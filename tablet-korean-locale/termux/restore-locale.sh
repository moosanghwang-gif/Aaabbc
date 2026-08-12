#!/data/data/com.termux/files/usr/bin/bash
# ===========================================================
#  한국어 로케일 복구 — 태블릿 단독 실행 (PC 불필요)
#
#  Termux 안에서 무선 디버깅으로 자기 자신에게 붙어
#  로케일과 앱별 언어를 재적용합니다.
#
#  최초 1회: ./pair-once.sh 로 페어링
#  이후    : 홈 화면 위젯을 탭하거나 이 스크립트를 실행
# ===========================================================

set -uo pipefail

LOCALES="ko-KR,en-US"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$SCRIPT_DIR/app-locales.txt"
PORT_CACHE="$HOME/.cache/korean-locale-port"

bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'
green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'

ok()   { printf '  %s%s%s\n' "$green" "$*" "$reset"; }
warn() { printf '  %s%s%s\n' "$yellow" "$*" "$reset"; }
fail() { printf '  %s%s%s\n' "$red" "$*" "$reset"; }

notify() {
    command -v termux-toast >/dev/null 2>&1 && termux-toast -s "$1" 2>/dev/null || true
}

printf '\n%s한국어 로케일 복구%s  |  %s\n\n' "$bold" "$reset" "$LOCALES"

# ---------- adb 확인 ----------
if ! command -v adb >/dev/null 2>&1; then
    fail "[실패] adb 가 없습니다.  pkg install android-tools"
    exit 1
fi

mkdir -p "$(dirname "$PORT_CACHE")"

# ---------- 이미 붙어 있나 ----------
is_connected() {
    adb devices 2>/dev/null | grep -qE '^127\.0\.0\.1:[0-9]+[[:space:]]+device$'
}

try_connect() {
    local port="$1"
    [[ -z "$port" ]] && return 1
    adb connect "127.0.0.1:${port}" 2>&1 | grep -qiE 'connected to' && is_connected
}

printf '[1/5] 기기 연결 중...\n'

if is_connected; then
    ok "이미 연결되어 있습니다"
else
    linked=0

    # (a) 캐시된 포트
    if [[ -f "$PORT_CACHE" ]]; then
        cached="$(tr -cd '0-9' < "$PORT_CACHE")"
        if try_connect "$cached"; then
            ok "연결됨 (저장된 포트 $cached)"
            linked=1
        fi
    fi

    # (b) mDNS 자동 탐색
    if [[ $linked -eq 0 ]]; then
        printf '  %s포트 자동 탐색 중...%s\n' "$dim" "$reset"
        mdns_port="$(adb mdns services 2>/dev/null \
            | awk '/_adb-tls-connect/ {n=split($NF,a,":"); print a[n]; exit}')"
        if try_connect "$mdns_port"; then
            ok "연결됨 (자동 탐색 $mdns_port)"
            printf '%s' "$mdns_port" > "$PORT_CACHE"
            linked=1
        fi
    fi

    # (c) 직접 입력
    if [[ $linked -eq 0 ]]; then
        warn "자동 탐색 실패 — 포트를 직접 입력해야 합니다."
        printf '\n'
        printf '  설정 → 시스템 → 개발자 옵션 → 무선 디버깅 을 열고\n'
        printf '  "IP 주소 및 포트" 에 표시된 포트 번호를 입력하세요.\n'
        printf '  %s(페어링 팝업의 포트가 아니라 메인 화면의 포트입니다)%s\n\n' "$dim" "$reset"
        read -r -p "  포트: " manual
        manual="$(printf '%s' "$manual" | tr -cd '0-9')"
        if try_connect "$manual"; then
            ok "연결됨 ($manual)"
            printf '%s' "$manual" > "$PORT_CACHE"
            linked=1
        fi
    fi

    if [[ $linked -eq 0 ]]; then
        printf '\n'
        fail "[실패] 연결하지 못했습니다."
        printf '\n  점검할 것:\n'
        printf '    - 무선 디버깅이 켜져 있는지 (재부팅하면 꺼질 수 있음)\n'
        printf '    - 페어링을 한 적이 있는지 → ./pair-once.sh 실행\n'
        printf '    - 포트가 바뀌었는지 (무선 디버깅을 껐다 켜면 바뀝니다)\n\n'
        notify "로케일 복구 실패: 연결 안 됨"
        exit 1
    fi
fi

# ---------- 변경 전 ----------
printf '\n[2/5] 변경 전 상태\n'
BEFORE="$(adb shell settings get system system_locales 2>/dev/null | tr -d '\r')"
PROP="$(adb shell getprop persist.sys.locale 2>/dev/null | tr -d '\r')"
printf '  %ssystem_locales    :%s %s\n' "$dim" "$reset" "${BEFORE:-(없음)}"
printf '  %spersist.sys.locale:%s %s\n' "$dim" "$reset" "${PROP:-(없음)}"

if [[ "$BEFORE" == "$LOCALES" ]]; then
    ok "이미 올바른 값입니다 — 변경할 게 없습니다."
    notify "로케일 정상 (ko-KR)"
    exit 0
fi

# ---------- 적용 ----------
printf '\n[3/5] 시스템 로케일 적용 중...\n'
if adb shell settings put system system_locales "$LOCALES" >/dev/null 2>&1; then
    ok "완료"
else
    warn "[경고] settings put 실패 — 설정 앱에서 직접 바꿔야 할 수 있습니다."
fi

# ---------- 앱별 ----------
printf '\n[4/5] 앱별 언어 적용 중...\n'
if [[ ! -f "$PKGLIST" ]]; then
    warn "app-locales.txt 없음 — 건너뜁니다."
else
    count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        pkg="${line%%#*}"
        pkg="$(printf '%s' "$pkg" | tr -d '[:space:]')"
        [[ -z "$pkg" ]] && continue
        if adb shell cmd locale set-app-locales "$pkg" --user current --locales "$LOCALES" >/dev/null 2>&1; then
            printf '  - %-40s %s적용%s\n' "$pkg" "$green" "$reset"
            count=$((count + 1))
        fi
    done < "$PKGLIST"
    printf '  %s개 앱 적용\n' "$count"
fi

# ---------- 검증 ----------
printf '\n[5/5] 변경 후 상태\n'
AFTER="$(adb shell settings get system system_locales 2>/dev/null | tr -d '\r')"
printf '  %ssystem_locales    :%s %s\n' "$dim" "$reset" "${AFTER:-(없음)}"

printf '\n'
if [[ "$AFTER" == "$LOCALES" ]]; then
    ok "[성공] 로케일이 복구되었습니다."
    notify "한국어 로케일 복구 완료"
    printf '\n  재부팅해야 모든 앱에 반영됩니다.\n\n'
else
    warn "[주의] 기대: $LOCALES / 실제: ${AFTER:-(없음)}"
    warn "       설정 앱에서 수동으로 지정해 주세요."
    notify "로케일 복구 실패 — 수동 설정 필요"
fi
