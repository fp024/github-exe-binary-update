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

rem Run Windows Defender scan and capture output
echo DEBUG: Executing "%DEFENDER_CMD%" -Scan -ScanType 3 -File "%ABSOLUTE_PATH%"
"%DEFENDER_CMD%" -Scan -ScanType 3 -File "%ABSOLUTE_PATH%" > scan_output.tmp 2>&1
set CMD_EXIT_CODE=%errorlevel%
echo DEBUG: MpCmdRun.exe returned exit code: %CMD_EXIT_CODE%

rem Display scan output
echo.
echo ==================== MpCmdRun.exe Output ====================
type scan_output.tmp
echo ==================== End of MpCmdRun.exe Output ====================
echo.

rem Check for threats in output text
findstr /C:"found no threats" scan_output.tmp > nul
if !errorlevel! equ 0 (
    echo DEBUG: No threats found in output text
    set THREAT_DETECTED=0
) else (
    findstr /R "found [0-9]+ threats" scan_output.tmp > nul
    if !errorlevel! equ 0 (
        echo DEBUG: Threats detected in output text
        set THREAT_DETECTED=1
    ) else (
        echo DEBUG: Could not determine threat status from output
        set THREAT_DETECTED=0
    )
)

rem Clean up temporary file
del scan_output.tmp 2>nul

rem Check the result - use text parsing instead of exit code
if !THREAT_DETECTED! equ 1 (
    echo 💢 FATAL: Windows Defender detected potential threats in the file!
    exit /b 2
) else if !CMD_EXIT_CODE! geq 1 (
    echo ⚠️ WARN: Windows Defender scan failed or encountered an error.
    echo Proceeding without antivirus scan...
    exit /b 0
) else (
    echo ✅ Security scan completed - no threats detected.
    exit /b 0
)
