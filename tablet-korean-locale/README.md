# Legion Tab Y700 한국어 로케일 복구 스크립트

Legion Tab Y700 (TB322FC / ZUXOS / Android 16)에서 **OTA 업데이트 후 시스템 언어가
`zh-CN`으로 되돌아가는 문제**를 한 번에 되돌리기 위한 스크립트입니다.

중국 내수용 ROM은 시스템 파티션을 갱신할 때 설정 DB의 로케일 값을 공장 기본값
(`ro.product.locale` = `zh-CN`)으로 초기화하는 경우가 있습니다. 근본 해결은
루트 권한이 있어야 가능하므로, 여기서는 **업데이트 직후 한 번 실행해서 되돌리는**
방식을 택했습니다.

## 준비

1. 태블릿에서 **개발자 옵션** 활성화
   설정 → 태블릿 정보 → 소프트웨어 버전(또는 빌드 번호)을 7회 연속 탭
2. 개발자 옵션에서 **USB 디버깅** 켜기
3. PC에 [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools) 설치
4. USB로 연결하고, 태블릿에 뜨는 *USB 디버깅을 허용하시겠습니까?* 팝업 승인

## 실행

### Windows — `시작하기.bat` 더블클릭

이 파일 **하나만** 더블클릭하면 됩니다. 위의 "준비" 3번(adb 설치)도 건너뛸 수 있습니다.

1. adb가 없으면 Google 공식 배포처에서 자동으로 내려받습니다 (약 10MB,
   **이 폴더 안에만** 저장하며 시스템에는 아무것도 설치하지 않습니다)
2. 태블릿에서 해야 할 일을 화면에 안내합니다
3. 이어서 로케일 복구를 실행합니다

세 파일이 **같은 폴더**에 있어야 합니다:

```
시작하기.bat
restore-korean-locale.bat
app-locales.txt
```

> 배치 파일은 한국어 Windows 기본 코드페이지(CP949)로 저장되어 있습니다.
> 메모장 등으로 편집한다면 인코딩을 유지해 주세요. UTF-8로 저장하면
> 화면의 한글이 깨집니다.

### macOS / Linux

```bash
chmod +x restore-korean-locale.sh
./restore-korean-locale.sh
```

adb는 직접 설치해야 합니다 (`brew install android-platform-tools` 또는
`sudo apt install adb`).

## 스크립트가 하는 일

| 단계 | 내용 |
|---|---|
| 1 | adb 설치 및 기기 연결 확인 (`unauthorized` 상태도 감지) |
| 2 | 변경 전 `system_locales` · `persist.sys.locale` 출력 |
| 3 | 시스템 로케일을 `ko-KR,en-US` 로 설정 |
| 4 | `app-locales.txt` 의 앱들에 개별 언어 강제 |
| 5 | 적용 결과 검증 후 재부팅 여부 확인 |

폴백을 `en-US`로 두는 것이 핵심입니다. 번역이 누락된 문자열이 중국어 대신
영어로 표시됩니다.

## app-locales.txt

앱별 언어를 강제할 패키지 목록입니다. 한 줄에 하나씩 적고 `#` 뒤는 주석입니다.
설치되지 않았거나 한국어를 지원하지 않는 앱은 자동으로 건너뜁니다.

패키지명 확인:

```bash
adb shell pm list packages | grep -i kakao
adb shell dumpsys activity activities | grep mResumedActivity   # 현재 화면의 앱
```

## 알아둘 것

- `settings put system system_locales` 는 기기에 따라 **루트 없이는 반영되지 않거나
  재부팅 시 초기화**될 수 있습니다. 스크립트가 검증 단계에서 이를 알려줍니다.
  실패한다면 설정 앱에서 직접 언어를 바꾸는 쪽이 더 오래 유지됩니다.
- ZUXOS 시스템 앱에 한국어 문자열 자체가 없는 항목(`CPU`, `RAM`,
  `Available: …GB` 등)은 이 스크립트로 바뀌지 않습니다. ROM 리소스를 수정해야
  하는 영역입니다.
- 자동 업데이트를 꺼두면 이 스크립트를 돌릴 시점을 직접 정할 수 있습니다.

## 되돌리기

```bash
adb shell settings put system system_locales zh-CN
adb shell cmd locale set-app-locales <패키지명> --user current --locales ""
```
