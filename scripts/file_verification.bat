@echo off
setlocal enabledelayedexpansion

rem Parameters: %1 = file path, %2 = expected size, %3 = expected hash
set "FILE_TO_VERIFY=%~1"
set "EXPECTED_SIZE=%~2"
set "EXPECTED_HASH=%~3"

if "%FILE_TO_VERIFY%"=="" (
    echo ERROR: File path not provided for verification.
    exit /b 1
)

if "%EXPECTED_SIZE%"=="" (
    echo ERROR: Expected file size not provided.
    exit /b 1
)

if "%EXPECTED_HASH%"=="" (
    echo ERROR: Expected SHA256 hash not provided.
    exit /b 1
)

if not exist "%FILE_TO_VERIFY%" (
    echo ERROR: File to verify does not exist: %FILE_TO_VERIFY%
    exit /b 1
)

echo Verifying file size and SHA256 hash...

rem Check file size first
for /f "delims=" %%i in ('powershell -Command "(Get-Item '%FILE_TO_VERIFY%').Length"') do set ACTUAL_SIZE=%%i
echo Actual file size: !ACTUAL_SIZE! bytes

if "!ACTUAL_SIZE!" neq "%EXPECTED_SIZE%" (
    echo ERROR: File size mismatch! Expected: %EXPECTED_SIZE%, Actual: !ACTUAL_SIZE!
    exit /b 2
)

echo ✅ File size verification passed.

echo Calculating SHA256 hash... (this may take a moment)

rem Calculate SHA256 hash
for /f "delims=" %%i in ('powershell -Command "$hash = Get-FileHash '%FILE_TO_VERIFY%' -Algorithm SHA256; $hash.Hash.ToLower()"') do set ACTUAL_HASH=%%i
echo Actual SHA256: !ACTUAL_HASH!

if "!ACTUAL_HASH!" neq "%EXPECTED_HASH%" (
    echo ERROR: SHA256 hash mismatch! 
    echo Expected: %EXPECTED_HASH%
    echo Actual:   !ACTUAL_HASH!
    exit /b 3
)

echo ✅ SHA256 verification passed. File integrity confirmed!
exit /b 0
