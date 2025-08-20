@echo off
setlocal enabledelayedexpansion

rem Constants
set "DEFENDER_CMD=C:\Program Files\Windows Defender\MpCmdRun.exe"

rem Parameters: %1 = file path to scan
set "FILE_TO_SCAN=%~1"

if "%FILE_TO_SCAN%"=="" (
    echo ⚠️ WARN: File path not provided for security scan.
    exit /b 1
)

if not exist "%FILE_TO_SCAN%" (
    echo ⚠️ WARN: File to scan does not exist: %FILE_TO_SCAN%
    exit /b 1
)

rem Convert to absolute path
for /f "delims=" %%i in ("%FILE_TO_SCAN%") do set "ABSOLUTE_PATH=%%~fi"

rem Check if Windows Defender command line tool exists
if not exist "%DEFENDER_CMD%" (
    echo INFO: Windows Defender command line tool not found.
    echo Skipping antivirus scan and proceeding with update...
    exit /b 0
)

echo Running Windows Defender scan on: %ABSOLUTE_PATH%

rem Run Windows Defender scan using command line (suppress verbose output)
"%DEFENDER_CMD%" -Scan -ScanType 3 -File "%ABSOLUTE_PATH%" >nul 2>&1

rem Check the result
if errorlevel 2 (
    echo 💢 CRITICAL: Windows Defender detected potential threats in the file!
    exit /b 2
) else if errorlevel 1 (
    echo ⚠️ WARNING: Windows Defender scan failed or encountered an error.
    echo Proceeding without antivirus scan...
    exit /b 0
) else (
    echo ✅ Security scan completed - no threats detected.
    exit /b 0
)
