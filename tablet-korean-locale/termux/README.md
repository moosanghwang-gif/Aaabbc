# 태블릿 단독 실행 (PC 불필요)

Termux 안의 adb로 **태블릿이 자기 자신에게 무선 디버깅으로 접속**해서 로케일을
복구합니다. Android 11 이상이면 동작하며, 루트가 필요 없습니다.

Legion Tab Y700은 Android 16이라 조건을 모두 만족합니다.

## 왜 이 방식인가

| 방식 | 루트 | PC | 자동화 |
|---|---|---|---|
| PC + adb (상위 폴더 스크립트) | 불필요 | **필요** | 수동 |
| **Termux + 무선 디버깅** | 불필요 | 불필요 | 위젯 1탭 / 부팅 시 자동 |
| Magisk `service.d` | **필요** | 불필요 | 완전 자동 |

## 1. Termux 설치

**Play 스토어 버전을 쓰지 마세요.** 업데이트가 중단된 구버전이라 `pkg install`이
깨집니다. [F-Droid](https://f-droid.org/packages/com.termux/) 또는
[GitHub 릴리스](https://github.com/termux/termux-app/releases)에서 받으세요.

같은 출처에서 애드온도 함께 설치합니다. **서명이 같아야 하므로 반드시 동일한
출처에서 받아야 합니다.**

- `Termux:Widget` — 홈 화면 1탭 실행
- `Termux:Boot` — 부팅 시 자동 실행 (선택)
- `Termux:API` — 완료 토스트 알림 (선택)

## 2. 패키지 설치

```bash
pkg update && pkg upgrade
pkg install android-tools termux-api
```

## 3. 파일 배치

```bash
mkdir -p ~/.shortcuts
# 이 폴더의 세 파일을 ~/.shortcuts/ 로 복사
chmod +x ~/.shortcuts/*.sh
chmod 700 -R ~/.shortcuts   # Termux:Widget 요구사항
```

`app-locales.txt`도 같은 폴더에 있어야 합니다.

## 4. 무선 디버깅 켜기

```
설정 → 시스템 → 개발자 옵션 → 무선 디버깅
```

개발자 옵션이 안 보이면 `설정 → 태블릿 정보 → 소프트웨어 버전`을 7회 연속 탭하세요.

> **Android 13+ 팁** — 무선 디버깅을 집 Wi-Fi에 연결된 상태에서 켜면 해당 네트워크가
> *신뢰할 수 있는 네트워크*로 등록되어, 재부팅 후에도 자동으로 다시 켜집니다.
> 이게 켜져 있어야 아래 자동 실행이 의미가 있습니다.

## 5. 최초 1회 페어링

```bash
~/.shortcuts/pair-once.sh
```

무선 디버깅 화면에서 **"페어링 코드로 기기 페어링"**을 탭하면 6자리 코드와 포트가
뜹니다. 그 팝업을 **닫지 말고** 값을 입력하세요.

⚠️ 페어링 팝업의 포트와 무선 디버깅 메인 화면의 포트는 **서로 다릅니다.**
페어링에는 팝업 쪽 포트를 씁니다.

한 번 성공하면 키가 저장되어 다시 할 필요가 없습니다.

## 6. 실행

```bash
~/.shortcuts/restore-locale.sh
```

- 연결 포트는 자동 탐색합니다 (캐시 → mDNS → 직접 입력 순)
- **이미 로케일이 정상이면 아무것도 하지 않고 종료합니다.** 몇 번을 돌려도 안전합니다.

## 7. 홈 화면 1탭 버튼

홈 화면 → 위젯 → **Termux:Widget** 배치 → `restore-locale.sh` 선택.
업데이트한 날 아이콘 한 번 누르면 끝입니다.

## 8. 부팅 시 자동 실행 (선택)

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/locale.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sleep 30          # 무선 디버깅이 올라올 시간을 줍니다
~/.shortcuts/restore-locale.sh
termux-wake-unlock
EOF
chmod +x ~/.termux/boot/locale.sh
```

Termux:Boot 앱을 한 번 실행해두어야 등록됩니다. 배터리 최적화에서 Termux를
제외해야 안정적으로 동작합니다.

## 알아둘 제약

- **무선 디버깅은 재부팅 시 꺼질 수 있습니다.** Android 13+ 신뢰 네트워크 등록으로
  대부분 해결되지만, ROM에 따라 다릅니다. 꺼져 있으면 스크립트가 그 사실을 알려줍니다.
- **포트는 무선 디버깅을 껐다 켤 때마다 바뀝니다.** 스크립트가 자동으로 다시 찾고,
  실패하면 직접 입력받아 캐시에 저장합니다.
- **`settings put`이 막힌 기기라면** 이 방식으로도 안 됩니다. 스크립트가 검증
  단계에서 알려주며, 그때는 설정 앱에서 직접 바꾸는 수밖에 없습니다.
- **ZUXOS에 한국어 문자열이 없는 항목**(`CPU`, `RAM`, `Available: …GB`)은 어떤
  방법으로도 바뀌지 않습니다. ROM 리소스 자체의 문제입니다.

## 대안: Shizuku

스크립트 대신 GUI를 원한다면 [Shizuku](https://shizuku.rikka.app/) 13.6.0 이상을
쓸 수 있습니다. Android 16을 지원하고, **신뢰할 수 있는 Wi-Fi에서 루트 없이 부팅 후
자동 시작**됩니다. 다만 Shizuku 자체는 권한을 위임해주는 도구일 뿐이라, 실제로
명령을 실행할 앱(Tasker + Shizuku 플러그인 등)을 따로 붙여야 합니다. 파일 하나
복사해서 끝나는 Termux 쪽이 이 용도에는 더 간단합니다.
