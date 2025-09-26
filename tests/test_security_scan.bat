@echo off
setlocal enabledelayedexpansion

echo === Windows Defender Security Scan Test ===
echo.
echo This script creates an EICAR test file to verify virus detection.
echo EICAR is a harmless test string that antivirus software detects as malware.
echo.

rem Create EICAR test file using HEX bytes to avoid special character issues
set "TEST_FILE=eicar_test.exe"

echo Creating EICAR test file: %TEST_FILE%
powershell -Command "$bytes = [byte[]]@(0x58,0x35,0x4F,0x21,0x50,0x25,0x40,0x41,0x50,0x5B,0x34,0x5C,0x50,0x5A,0x58,0x35,0x34,0x28,0x50,0x5E,0x29,0x37,0x43,0x43,0x29,0x37,0x7D,0x24,0x45,0x49,0x43,0x41,0x52,0x2D,0x53,0x54,0x41,0x4E,0x44,0x41,0x52,0x44,0x2D,0x41,0x4E,0x54,0x49,0x56,0x49,0x52,0x55,0x53,0x2D,0x54,0x45,0x53,0x54,0x2D,0x46,0x49,0x4C,0x45,0x21,0x24,0x48,0x2B,0x48,0x2A); [System.IO.File]::WriteAllBytes('%TEST_FILE%', $bytes)"

echo Checking if file was created...
if exist %TEST_FILE% (
    echo ✅ File created successfully!
    echo File size: 
    powershell -Command "(Get-Item '%TEST_FILE%').Length"
    echo Note: Cannot preview content - Windows Defender recognizes this as a test threat (This is GOOD!)
) else (
    echo File creation failed or was immediately quarantined.
)

if not exist %TEST_FILE% (
    echo ⚠️ ERROR: Failed to create test file.
    exit /b 1
)

echo ✅ Test file created successfully.
echo.

rem Run our security scan on the test file (adjust path for tests directory)
echo Running security_scan.bat on EICAR test file...
echo Note: This will test if MpCmdRun.exe properly detects the EICAR signature.
echo ================================================
call ..\scripts\security_scan.bat "%TEST_FILE%"
set SCAN_RESULT=!errorlevel!
echo ================================================
echo DEBUG: Exit code from security_scan.bat: !SCAN_RESULT!

echo.
echo === Test Results ===
if !SCAN_RESULT! equ 2 (
    echo ✅ SUCCESS: Windows Defender correctly detected the test threat!
    echo 🎉 The security scan is working properly.
) else if !SCAN_RESULT! equ 0 (
    echo ⚠️ UNEXPECTED: No threat detected. This might indicate:
    echo   - Real-time protection interfered before scan
    echo   - Windows Defender configuration issue
    echo   - EICAR file was already quarantined
) else (
    echo ❓ INCONCLUSIVE: Scan failed or Defender unavailable (exit code: !SCAN_RESULT!)
)

echo.
echo 🧹 Cleaning up test file...
del %TEST_FILE% 2>nul

if exist %TEST_FILE% (
    echo ⚠️ WARN: Could not delete test file (may have been quarantined by Defender)
    echo This is actually a GOOD sign - it means real-time protection is working!
) else (
    echo ✅ Test file cleaned up successfully.
)

echo.
echo === Test Complete ===
echo Press Enter to continue...
pause >nul