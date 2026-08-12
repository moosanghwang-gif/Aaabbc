@echo off
setlocal enabledelayedexpansion

rem ===========================================================
rem  Legion Tab Y700 (ZUXOS / Android 16) 한국어 로케일 복구
rem
rem  OTA 업데이트 후 시스템 언어가 zh-CN 으로 되돌아갔을 때
rem  이 스크립트를 실행하면 한 번에 재적용됩니다.
rem
rem  사용 전 준비:
rem    1) 태블릿 개발자 옵션 → USB 디버깅 켜기
rem    2) USB 로 PC 연결, 태블릿 화면의 디버깅 허용 팝업 승인
rem    3) 이 파일을 더블클릭
rem ===========================================================

set "LOCALES=ko-KR,en-US"
set "PKGLIST=%~dp0app-locales.txt"

echo.
echo ============================================
echo   한국어 로케일 복구  ^| %LOCALES%
echo ============================================
echo.

rem ---------- adb 존재 확인 ----------
where adb >nul 2>&1
if errorlevel 1 (
    echo [실패] adb 를 찾을 수 없습니다.
    echo.
    echo   Android SDK Platform Tools 를 내려받아 압축을 푼 뒤,
    echo   그 폴더를 시스템 PATH 에 추가하거나
    echo   platform-tools 폴더 안에서 이 스크립트를 실행하세요.
    echo   https://developer.android.com/tools/releases/platform-tools
    echo.
    pause
    exit /b 1
)

rem ---------- 기기 연결 확인 ----------
echo [1/5] 기기 확인 중...
adb start-server >nul 2>&1

set "DEVICE="
for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
    if "%%b"=="device" set "DEVICE=%%a"
    if "%%b"=="unauthorized" (
        echo   [실패] 기기가 unauthorized 상태입니다.
        echo          태블릿 화면의 "USB 디버깅을 허용하시겠습니까?" 팝업을 승인하세요.
        echo.
        pause
        exit /b 1
    )
)

if not defined DEVICE (
    echo   [실패] 연결된 기기가 없습니다. USB 케이블과 디버깅 설정을 확인하세요.
    echo.
    pause
    exit /b 1
)
echo   연결됨: !DEVICE!

rem ---------- 변경 전 상태 ----------
echo.
echo [2/5] 변경 전 상태
for /f "delims=" %%v in ('adb shell settings get system system_locales 2^>nul') do set "BEFORE=%%v"
for /f "delims=" %%v in ('adb shell getprop persist.sys.locale 2^>nul') do set "PROP=%%v"
echo   system_locales    : !BEFORE!
echo   persist.sys.locale: !PROP!

rem ---------- 시스템 로케일 적용 ----------
echo.
echo [3/5] 시스템 로케일 적용 중...
adb shell settings put system system_locales "%LOCALES%"
if errorlevel 1 (
    echo   [경고] settings put 실패. 이 기기는 루트 없이 이 방식이 막혀 있을 수 있습니다.
    echo          설정 앱에서 직접 언어를 바꾸는 쪽이 더 오래 유지됩니다.
) else (
    echo   완료
)

rem ---------- 앱별 로케일 ----------
echo.
echo [4/5] 앱별 언어 적용 중...
if not exist "%PKGLIST%" (
    echo   app-locales.txt 없음 - 건너뜁니다.
) else (
    set "COUNT=0"
    for /f "usebackq eol=# tokens=1 delims= " %%p in ("%PKGLIST%") do (
        if not "%%p"=="" (
            adb shell cmd locale set-app-locales %%p --user current --locales %LOCALES% >nul 2>&1
            if errorlevel 1 (
                echo   - %%p  [건너뜀: 미설치 또는 미지원]
            ) else (
                echo   - %%p  적용
                set /a COUNT+=1
            )
        )
    )
    echo   !COUNT! 개 앱 처리
)

rem ---------- 검증 ----------
echo.
echo [5/5] 변경 후 상태
for /f "delims=" %%v in ('adb shell settings get system system_locales 2^>nul') do set "AFTER=%%v"
echo   system_locales    : !AFTER!

echo.
if /i "!AFTER!"=="%LOCALES%" (
    echo   [성공] 로케일이 적용되었습니다.
) else (
    echo   [주의] 기대값과 다릅니다. 기대: %LOCALES% / 실제: !AFTER!
    echo          설정 앱에서 수동으로 언어를 지정해 주세요.
)

echo.
echo ============================================
echo   재부팅해야 모든 앱에 반영됩니다.
echo ============================================
set /p "DOREBOOT=지금 재부팅할까요? (y/N): "
if /i "!DOREBOOT!"=="y" (
    echo 재부팅 중...
    adb reboot
) else (
    echo 나중에 직접 재부팅하세요.
)

echo.
pause
endlocal
