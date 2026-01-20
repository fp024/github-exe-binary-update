@echo off
:: 관리자 권한으로 재실행 스크립트
:: 사용법: call elevate.bat "원본스크립트경로" [인자1] [인자2] ...

setlocal enabledelayedexpansion

:: 심볼 로드
call "%~dp0symbols.bat"

:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% == 0 (
    echo %SYM_INFO% Already running with administrator privileges.
    exit /b 0
)

:: 전달받은 모든 인자를 하나의 문자열로 조합
set "SCRIPT_PATH=%~1"
set "ARGS="

:parse_args
shift
if "%~1"=="" goto run_elevated
set "ARGS=!ARGS! %1"
goto parse_args

:run_elevated
echo %SYM_INFO% Requesting administrator privileges...
powershell -Command "Start-Process '%SCRIPT_PATH%' -ArgumentList '%ARGS%' -Verb RunAs"
exit /b %errorlevel%
