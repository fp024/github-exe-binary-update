@echo off
setlocal enabledelayedexpansion

set "SOURCE_DIR=%~dp0"

:: 심볼릭 링크 생성 가능 여부 확인
call "%SOURCE_DIR%scripts\check_symlink.bat"
if %errorlevel% neq 0 (
    echo ❌ Cannot create symbolic links on this system.
    echo.
    echo Attempting to elevate privileges...
    echo.
    
    :: 관리자 권한으로 재실행
    call "%SOURCE_DIR%scripts\elevate.bat" "%~f0" %*
    exit /b %errorlevel%
)

:: 인자 확인
if "%~1"=="" (
    echo Usage: install.bat [program-name] [target-directory]
    echo.
    echo Available programs:
    for %%f in (settings\*.properties) do (
        set "filename=%%~nf"
        echo   - !filename!
    )
    echo.
    echo Example:
    echo   install.bat google-java-format C:\google-java-format
    pause
    exit /b 1
)

if "%~2"=="" (
    echo ❌ Target directory is required.
    echo.
    echo Usage: install.bat [program-name] [target-directory]
    echo Example:
    echo   install.bat google-java-format C:\google-java-format
    pause
    exit /b 1
)

set "PROGRAM_NAME=%~1"
set "TARGET_DIR=%~2"
set "PROPERTIES_FILE=%SOURCE_DIR%settings\%PROGRAM_NAME%.properties"

:: properties 파일 존재 확인
if not exist "%PROPERTIES_FILE%" (
    echo ❌ Settings file not found: %PROPERTIES_FILE%
    echo.
    echo Available programs:
    for %%f in (settings\*.properties) do (
        set "filename=%%~nf"
        echo   - !filename!
    )
    pause
    exit /b 1
)

:: 대상 디렉토리 생성 (존재하지 않으면)
if not exist "%TARGET_DIR%" (
    echo Creating target directory: %TARGET_DIR%
    mkdir "%TARGET_DIR%" 2>nul
    if !errorlevel! neq 0 (
        echo ❌ Failed to create directory: %TARGET_DIR%
        pause
        exit /b 1
    )
)

echo.
echo ====================================
echo  Installing: %PROGRAM_NAME%
echo  Target: %TARGET_DIR%
echo ====================================
echo.

:: 1. settings.properties 심볼릭 링크 생성
echo [1/3] Creating symbolic link for settings.properties...
if exist "%TARGET_DIR%\settings.properties" (
    echo   ⚠ settings.properties already exists. Removing...
    del "%TARGET_DIR%\settings.properties" 2>nul
)
mklink "%TARGET_DIR%\settings.properties" "%PROPERTIES_FILE%"
if %errorlevel% equ 0 (
    echo   ✅ settings.properties linked successfully
) else (
    echo   ❌ Failed to create symbolic link for settings.properties
    pause
    exit /b 1
)

:: 2. update.bat 심볼릭 링크 생성
echo.
echo [2/3] Creating symbolic link for update.bat...
if exist "%TARGET_DIR%\update.bat" (
    echo   ⚠ update.bat already exists. Removing...
    del "%TARGET_DIR%\update.bat" 2>nul
)
mklink "%TARGET_DIR%\update.bat" "%SOURCE_DIR%update.bat"
if %errorlevel% equ 0 (
    echo   ✅ update.bat linked successfully
) else (
    echo   ❌ Failed to create symbolic link for update.bat
    pause
    exit /b 1
)

:: 3. scripts 디렉토리 정션 링크 생성
echo.
echo [3/3] Creating junction link for scripts directory...
if exist "%TARGET_DIR%\scripts" (
    echo   ⚠ scripts already exists. Removing...
    rmdir "%TARGET_DIR%\scripts" 2>nul
)
mklink /J "%TARGET_DIR%\scripts" "%SOURCE_DIR%scripts"
if %errorlevel% equ 0 (
    echo   ✅ scripts directory linked successfully
) else (
    echo   ❌ Failed to create junction link for scripts
    pause
    exit /b 1
)

echo.
echo ====================================
echo 🎉 Installation completed successfully!
echo ====================================
echo.
echo You can now run: cd /d "%TARGET_DIR%" ^&^& update.bat
echo.
pause
