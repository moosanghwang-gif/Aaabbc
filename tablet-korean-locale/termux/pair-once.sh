#!/data/data/com.termux/files/usr/bin/bash
# ===========================================================
#  1회용 페어링 — 처음 한 번만 실행하면 됩니다
#
#  태블릿이 자기 자신에게 adb 로 붙을 수 있도록 페어링합니다.
#  한 번 성공하면 키가 저장되어, 이후에는 restore-locale.sh 만
#  실행하면 됩니다.
# ===========================================================

set -uo pipefail

bold=$'\033[1m'; dim=$'\033[2m'; red=$'\033[31m'
green=$'\033[32m'; yellow=$'\033[33m'; reset=$'\033[0m'

printf '\n%s무선 디버깅 페어링 (1회용)%s\n\n' "$bold" "$reset"

if ! command -v adb >/dev/null 2>&1; then
    printf '%s[실패]%s adb 가 없습니다. 먼저 설치하세요:\n\n' "$red" "$reset"
    printf '    pkg install android-tools\n\n'
    exit 1
fi

cat <<'GUIDE'
준비 순서 — 이 창을 보면서 그대로 따라 하세요.

  1. 설정 → 시스템 → 개발자 옵션 → 무선 디버깅  켜기
  2. 무선 디버깅 화면에서 "페어링 코드로 기기 페어링" 탭
  3. 화면에 뜨는 6자리 코드와 포트 번호를 확인
     (예: IP 주소 및 포트  192.168.0.5:41234  → 포트는 41234)
  4. 그 화면을 띄워둔 채로 아래에 값을 입력

주의: 페어링 화면을 닫으면 코드가 만료됩니다. 창을 유지하세요.

GUIDE

read -r -p "페어링 포트 (예: 41234): " pair_port
read -r -p "6자리 페어링 코드   : " pair_code

pair_port="$(printf '%s' "$pair_port" | tr -cd '0-9')"
pair_code="$(printf '%s' "$pair_code" | tr -cd '0-9')"

if [[ -z "$pair_port" || -z "$pair_code" ]]; then
    printf '\n%s[실패]%s 포트와 코드를 모두 입력해야 합니다.\n\n' "$red" "$reset"
    exit 1
fi

printf '\n%s페어링 시도 중...%s\n' "$dim" "$reset"
if adb pair "127.0.0.1:${pair_port}" "$pair_code"; then
    printf '\n%s[성공]%s 페어링이 저장되었습니다.\n' "$green" "$reset"
    printf '이제부터는 %srestore-locale.sh%s 만 실행하면 됩니다.\n\n' "$bold" "$reset"
else
    printf '\n%s[실패]%s 페어링에 실패했습니다.\n\n' "$red" "$reset"
    printf '확인할 것:\n'
    printf '  - 페어링 화면이 아직 열려 있는지 (닫으면 코드 만료)\n'
    printf '  - 포트를 "무선 디버깅" 메인 화면이 아니라\n'
    printf '    "페어링 코드로 기기 페어링" 팝업의 것으로 입력했는지\n'
    printf '    (두 포트는 서로 다릅니다)\n\n'
    exit 1
fi
