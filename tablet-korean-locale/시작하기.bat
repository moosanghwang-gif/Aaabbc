@echo off
setlocal enabledelayedexpansion
title 태블릿 한국어 로케일 복구

rem ===========================================================
rem  이 파일 하나만 더블클릭하면 됩니다.
rem
rem  adb(안드로이드 연결 도구)가 없으면 자동으로 내려받고,
rem  그다음 로케일 복구 스크립트를 실행합니다.
rem ===========================================================

set "HERE=%~dp0"
set "PT=%HERE%platform-tools"
set "ZIP=%HERE%platform-tools.zip"
set "URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

echo.
echo ============================================================
echo    태블릿 한국어 로케일 복구
echo ============================================================
echo.

rem ---------- adb 찾기 ----------
set "ADBDIR="

where adb >nul 2>&1
if not errorlevel 1 (
    echo [준비] adb 가 이미 설치되어 있습니다.
    goto :run
)

if exist "%PT%\adb.exe" (
    echo [준비] 이전에 받아둔 adb 를 사용합니다.
    set "ADBDIR=%PT%"
    goto :run
)

rem ---------- adb 자동 설치 ----------
echo [준비] adb 가 없습니다. 자동으로 내려받겠습니다.
echo        용량은 약 10MB 이고, 이 폴더 안에만 저장됩니다.
echo        (시스템에 아무것도 설치하지 않습니다)
echo.

where curl >nul 2>&1
if errorlevel 1 (
    echo [실패] curl 을 찾을 수 없습니다. Windows 10 이상이 필요합니다.
    echo.
    echo        직접 받으시려면:
    echo        %URL%
    echo        압축을 풀어 platform-tools 폴더를 이 위치에 두세요:
    echo        %HERE%
    echo.
    pause
    exit /b 1
)

echo        내려받는 중...
curl -L --fail --progress-bar -o "%ZIP%" "%URL%"
if errorlevel 1 (
    echo.
    echo [실패] 다운로드에 실패했습니다. 인터넷 연결을 확인하세요.
    echo.
    pause
    exit /b 1
)

echo        압축 푸는 중...
where tar >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Expand-Archive -Force -LiteralPath '%ZIP%' -DestinationPath '%HERE%'" 2>nul
) else (
    tar -xf "%ZIP%" -C "%HERE%"
)

if not exist "%PT%\adb.exe" (
    echo.
    echo [실패] 압축 해제에 실패했습니다.
    echo        %ZIP% 을 직접 풀어서 platform-tools 폴더를 만들어 주세요.
    echo.
    pause
    exit /b 1
)

del /q "%ZIP%" >nul 2>&1
set "ADBDIR=%PT%"
echo        완료
echo.

:run
if defined ADBDIR set "PATH=%ADBDIR%;%PATH%"

rem ---------- 태블릿 준비 안내 ----------
echo ------------------------------------------------------------
echo   태블릿에서 아래 3가지를 확인하세요.
echo ------------------------------------------------------------
echo.
echo   1) 개발자 옵션 켜기
echo      설정 - 태블릿 정보 - 소프트웨어 버전 을 7번 연속 탭
echo.
echo   2) 개발자 옵션 안에서 [USB 디버깅] 켜기
echo.
echo   3) USB 케이블로 PC 와 연결
echo      태블릿에 "USB 디버깅을 허용하시겠습니까?" 팝업이 뜨면
echo      [항상 허용] 체크 후 확인
echo.
echo ------------------------------------------------------------
echo.
pause

if not exist "%HERE%restore-korean-locale.bat" (
    echo.
    echo [실패] restore-korean-locale.bat 이 같은 폴더에 없습니다.
    echo        받은 파일들을 모두 한 폴더에 모아 주세요:
    echo          - 시작하기.bat
    echo          - restore-korean-locale.bat
    echo          - app-locales.txt
    echo.
    pause
    exit /b 1
)

call "%HERE%restore-korean-locale.bat"
endlocal
