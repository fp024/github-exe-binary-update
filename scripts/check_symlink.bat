@echo off
:: 심볼릭 링크 생성 가능 여부 확인 스크립트
:: Exit code: 0 = 성공, 1 = 실패

setlocal

set "TEMP_TEST_FILE=%TEMP%\symlink_test_%RANDOM%.tmp"
set "TEMP_TEST_LINK=%TEMP%\symlink_test_link_%RANDOM%.tmp"

:: 임시 테스트 파일 생성
echo test > "%TEMP_TEST_FILE%" 2>nul

:: 심볼릭 링크 생성 시도
mklink "%TEMP_TEST_LINK%" "%TEMP_TEST_FILE%" >nul 2>&1

if %errorlevel% neq 0 (
    :: 테스트 파일 정리
    del "%TEMP_TEST_FILE%" 2>nul
    exit /b 1
)

:: 테스트 파일 정리
del "%TEMP_TEST_LINK%" 2>nul
del "%TEMP_TEST_FILE%" 2>nul

exit /b 0
