#!/usr/bin/env bash
# ===========================================================
#  Legion Tab Y700 (ZUXOS / Android 16) 한국어 로케일 복구
#
#  OTA 업데이트 후 시스템 언어가 zh-CN 으로 되돌아갔을 때
#  이 스크립트를 실행하면 한 번에 재적용됩니다.
#
#  사용법:
#    chmod +x restore-korean-locale.sh
#    ./restore-korean-locale.sh
# ===========================================================

set -uo pipefail

LOCALES="ko-KR,en-US"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$SCRIPT_DIR/app-locales.txt"

bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'
green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'

info()  { printf '%s\n' "$*"; }
ok()    { printf '  %s%s%s\n' "$green" "$*" "$reset"; }
warn()  { printf '  %s%s%s\n' "$yellow" "$*" "$reset"; }
fail()  { printf '  %s%s%s\n' "$red" "$*" "$reset"; }

printf '\n%s한국어 로케일 복구%s  |  %s\n\n' "$bold" "$reset" "$LOCALES"

# ---------- adb 존재 확인 ----------
if ! command -v adb >/dev/null 2>&1; then
    fail "[실패] adb 를 찾을 수 없습니다."
    info ""
    info "  Android SDK Platform Tools 설치가 필요합니다:"
    info "    macOS    brew install android-platform-tools"
    info "    Ubuntu   sudo apt install adb"
    info "    직접받기  https://developer.android.com/tools/releases/platform-tools"
    exit 1
fi

# ---------- 기기 연결 확인 ----------
info "[1/5] 기기 확인 중..."
adb start-server >/dev/null 2>&1

if adb devices | awk 'NR>1 && $2=="unauthorized"{found=1} END{exit !found}'; then
    fail "[실패] 기기가 unauthorized 상태입니다."
    info '        태블릿 화면의 "USB 디버깅을 허용하시겠습니까?" 팝업을 승인하세요.'
    exit 1
fi

DEVICE="$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')"
if [[ -z "$DEVICE" ]]; then
    fail "[실패] 연결된 기기가 없습니다. USB 케이블과 디버깅 설정을 확인하세요."
    exit 1
fi
ok "연결됨: $DEVICE"

# ---------- 변경 전 상태 ----------
info ""
info "[2/5] 변경 전 상태"
BEFORE="$(adb shell settings get system system_locales 2>/dev/null | tr -d '\r')"
PROP="$(adb shell getprop persist.sys.locale 2>/dev/null | tr -d '\r')"
printf '  %ssystem_locales    :%s %s\n' "$dim" "$reset" "${BEFORE:-(없음)}"
printf '  %spersist.sys.locale:%s %s\n' "$dim" "$reset" "${PROP:-(없음)}"

# ---------- 시스템 로케일 적용 ----------
info ""
info "[3/5] 시스템 로케일 적용 중..."
if adb shell settings put system system_locales "$LOCALES" >/dev/null 2>&1; then
    ok "완료"
else
    warn "[경고] settings put 실패. 이 기기는 루트 없이 이 방식이 막혀 있을 수 있습니다."
    warn "       설정 앱에서 직접 언어를 바꾸는 쪽이 더 오래 유지됩니다."
fi

# ---------- 앱별 로케일 ----------
info ""
info "[4/5] 앱별 언어 적용 중..."
if [[ ! -f "$PKGLIST" ]]; then
    warn "app-locales.txt 없음 - 건너뜁니다."
else
    count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        pkg="${line%%#*}"
        pkg="$(printf '%s' "$pkg" | tr -d '[:space:]')"
        [[ -z "$pkg" ]] && continue
        if adb shell cmd locale set-app-locales "$pkg" --user current --locales "$LOCALES" >/dev/null 2>&1; then
            printf '  - %-42s %s적용%s\n' "$pkg" "$green" "$reset"
            count=$((count + 1))
        else
            printf '  - %-42s %s건너뜀 (미설치/미지원)%s\n' "$pkg" "$dim" "$reset"
        fi
    done < "$PKGLIST"
    info "  ${count} 개 앱 처리"
fi

# ---------- 검증 ----------
info ""
info "[5/5] 변경 후 상태"
AFTER="$(adb shell settings get system system_locales 2>/dev/null | tr -d '\r')"
printf '  %ssystem_locales    :%s %s\n' "$dim" "$reset" "${AFTER:-(없음)}"

info ""
if [[ "$AFTER" == "$LOCALES" ]]; then
    ok "[성공] 로케일이 적용되었습니다."
else
    warn "[주의] 기대값과 다릅니다. 기대: $LOCALES / 실제: ${AFTER:-(없음)}"
    warn "       설정 앱에서 수동으로 언어를 지정해 주세요."
fi

info ""
info "재부팅해야 모든 앱에 반영됩니다."
read -r -p "지금 재부팅할까요? (y/N): " reboot_now
if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
    info "재부팅 중..."
    adb reboot
else
    info "나중에 직접 재부팅하세요."
fi
