@echo off
setlocal enabledelayedexpansion

rem Check if settings.properties file exists
if not exist settings.properties (
    echo settings.properties file not found. Please create the file with the required settings.
    goto end
)

echo --- Options ---
rem Load settings from properties file, excluding comments and empty lines
for /f "usebackq tokens=1* delims=" %%i in (`findstr /r "^[^#].*" settings.properties`) do (
    echo %%i
    set "%%i"
)
echo ---------------

rem Check if the executable exists
if exist %EXECUTABLE_NAME% (
    rem Redirect both stdout and stderr to a temporary file
    %EXECUTABLE_NAME% %VERSION_OPTION% > temp_version.txt 2>&1
    rem Read the first line of the file and store it in an environment variable
    for /f "delims=" %%i in (temp_version.txt) do (
        set LOCAL_VERSION=%%i
    )
    rem Clean up the temporary file
    del temp_version.txt
) else (
    rem If file doesn't exist, set local version to none
    set LOCAL_VERSION=none
    echo %EXECUTABLE_NAME% not found locally.
)

rem Get the latest version and file info from GitHub in one API call
powershell -Command "$release = Invoke-RestMethod -Uri '%LATEST_VERSION_URL%'; $asset = $release.assets | Where-Object { $_.name -eq '%EXECUTABLE_NAME%' }; '@LATEST_TAG=' + $release.tag_name; '@EXPECTED_SIZE=' + $asset.size; '@EXPECTED_HASH=' + (($asset.digest -replace 'sha256:', '').ToLower())" > temp_release_info.txt

rem Parse the release info from temporary file
for /f "tokens=1,2 delims==" %%a in (temp_release_info.txt) do (
    if "%%a"=="@LATEST_TAG" set LATEST_TAG=%%b
    if "%%a"=="@EXPECTED_SIZE" set EXPECTED_SIZE=%%b
    if "%%a"=="@EXPECTED_HASH" set EXPECTED_HASH=%%b
)

rem Clean up temporary file
del temp_release_info.txt

rem Remove 'v' from the latest tag name
set LATEST_VERSION=%VERSION_PREFIX%%LATEST_TAG:v=%

echo Local  version: %LOCAL_VERSION%
echo Latest version: %LATEST_VERSION%
echo Expected file size: %EXPECTED_SIZE% bytes
echo Expected SHA256: %EXPECTED_HASH%


rem Compare versions and download if different or file doesn't exist
if "%LOCAL_VERSION%" == "%LATEST_VERSION%" (
  echo 💡 The latest version is already installed.
  goto end
)

echo ✨✨✨ Please Check Version ✨✨✨
:ask_continue
set /p userChoice="Would you like to update? (y/n): "
if /i "!userChoice!"=="y" (
    rem Continue with the script
) else if /i "!userChoice!"=="n" (
    echo Canceled by user.
    goto end
) else (
    echo Please enter y or n.
    goto ask_continue
)
echo Downloading the latest version of %EXECUTABLE_NAME%.
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%EXECUTABLE_NAME%_temp.exe'"

rem If the download is successful, verify file integrity

if not exist %EXECUTABLE_NAME%_temp.exe (
  echo Download failed.
  goto fail_end
)

echo Download successful.
echo Running virus scan...

rem Run security scan (optional - continues even if Defender unavailable)
call security_scan.bat "%EXECUTABLE_NAME%_temp.exe"
set SCAN_RESULT=!errorlevel!

if !SCAN_RESULT! equ 2 (
    echo 💢 CRITICAL: Potential malware detected! Update canceled for security.
    del %EXECUTABLE_NAME%_temp.exe
    goto fail_end
)

rem SCAN_RESULT 0 or 1 both allow continuation
if !SCAN_RESULT! equ 0 (
    echo ✅ Security check passed.
) else (
    echo ⚠️ Security scan unavailable - proceeding with caution.
)

echo Verifying file size and SHA256 hash...
rem Check file size first
for /f "delims=" %%i in ('powershell -Command "(Get-Item '%EXECUTABLE_NAME%_temp.exe').Length"') do set ACTUAL_SIZE=%%i
echo Actual file size: !ACTUAL_SIZE! bytes

if "!ACTUAL_SIZE!" neq "%EXPECTED_SIZE%" (
    echo ERROR: File size mismatch! Expected: %EXPECTED_SIZE%, Actual: !ACTUAL_SIZE!
    echo Deleting corrupted file...
    del %EXECUTABLE_NAME%_temp.exe
    goto fail_end
)

echo ✅ File size verification passed.

echo Calculating SHA256 hash... (this may take a moment)

rem Calculate SHA256 hash
for /f "delims=" %%i in ('powershell -Command "$hash = Get-FileHash '%EXECUTABLE_NAME%_temp.exe' -Algorithm SHA256; $hash.Hash.ToLower()"') do set ACTUAL_HASH=%%i
echo Actual SHA256: !ACTUAL_HASH!

if "!ACTUAL_HASH!" neq "%EXPECTED_HASH%" (
    echo ERROR: SHA256 hash mismatch! 
    echo Expected: %EXPECTED_HASH%
    echo Actual:   !ACTUAL_HASH!
    echo Deleting corrupted file...
    del %EXECUTABLE_NAME%_temp.exe
    goto fail_end
)

echo ✅ SHA256 verification passed. File integrity confirmed!
echo Replacing the original file...

if exist %EXECUTABLE_NAME% (
    del %EXECUTABLE_NAME%
)
ren %EXECUTABLE_NAME%_temp.exe %EXECUTABLE_NAME%
echo 🎉 File successfully updated and verified! 🎉

:end
echo 👍 Task completed. 👍
:fail_end
echo Press Enter key to continue...
set /p dummyVar=""
