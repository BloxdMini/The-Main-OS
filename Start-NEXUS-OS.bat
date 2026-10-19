@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "RELEASE_URL=https://github.com/BloxdMini/The-Main-OS/releases/latest/download/nexus-os.iso"
set "INSTALL_DIR=%LOCALAPPDATA%\NEXUS OS"
set "ISO_PATH=%INSTALL_DIR%\nexus-os.iso"
set "DOWNLOAD_PATH=%INSTALL_DIR%\nexus-os.iso.download"
set "MANIFEST_PATH=%INSTALL_DIR%\nexus-os.iso.parts.download"
set "QEMU_EXE="

if /I "%~1"=="--update" goto download_iso
if exist "%ISO_PATH%" goto find_qemu

:download_iso
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if errorlevel 1 (
  echo Could not create "%INSTALL_DIR%".
  pause
  exit /b 1
)

echo Downloading the latest NEXUS OS ISO manifest...
call :download_file "%RELEASE_URL%.parts" "%MANIFEST_PATH%"
if errorlevel 1 (
  del "%MANIFEST_PATH%" >nul 2>nul
  echo.
  echo Download failed. Check your internet connection or whether a tested release is published.
  pause
  exit /b 1
)
set "PART_COUNT="
set "EXPECTED_HASH="
<"%MANIFEST_PATH%" set /p "PART_COUNT="
for /f "usebackq skip=1 delims=" %%H in ("%MANIFEST_PATH%") do if not defined EXPECTED_HASH set "EXPECTED_HASH=%%H"
if not defined PART_COUNT goto invalid_manifest
if not defined EXPECTED_HASH goto invalid_manifest
for /f "delims=0123456789" %%A in ("!PART_COUNT!") do goto invalid_manifest
if !PART_COUNT! LEQ 0 goto invalid_manifest
if !PART_COUNT! GTR 100 goto invalid_manifest
if "!EXPECTED_HASH:~63,1!"=="" goto invalid_manifest
if not "!EXPECTED_HASH:~64,1!"=="" goto invalid_manifest

echo Downloading %PART_COUNT% ISO part(s)...
type nul > "%DOWNLOAD_PATH%"
if errorlevel 1 goto download_failed
set /a LAST_PART=PART_COUNT-1
for /L %%N in (0,1,!LAST_PART!) do (
  set "PART_NUMBER=0%%N"
  set "PART_NUMBER=!PART_NUMBER:~-2!"
  set "PART_PATH=%INSTALL_DIR%\nexus-os.iso.part-!PART_NUMBER!"
  call :download_file "%RELEASE_URL%.part-!PART_NUMBER!" "!PART_PATH!.download"
  if errorlevel 1 goto download_failed
  copy /b "%DOWNLOAD_PATH%"+"!PART_PATH!.download" "%DOWNLOAD_PATH%.next" >nul
  if errorlevel 1 goto download_failed
  move /y "%DOWNLOAD_PATH%.next" "%DOWNLOAD_PATH%" >nul
  if errorlevel 1 goto download_failed
  del "!PART_PATH!.download" >nul 2>nul
)

echo Verifying downloaded ISO...
for /f "delims=" %%H in ('powershell.exe -NoProfile -Command "(Get-FileHash -Algorithm SHA256 -LiteralPath '%DOWNLOAD_PATH%').Hash"') do set "ACTUAL_HASH=%%H"
if /I not "!ACTUAL_HASH!"=="!EXPECTED_HASH!" (
  echo ISO checksum verification failed. The downloaded file will not be used.
  del "%DOWNLOAD_PATH%" >nul 2>nul
  del "%MANIFEST_PATH%" >nul 2>nul
  pause
  exit /b 1
)
for %%F in ("%DOWNLOAD_PATH%") do if %%~zF LEQ 0 goto download_failed
move /y "%DOWNLOAD_PATH%" "%ISO_PATH%" >nul
if errorlevel 1 (
  echo Could not save the ISO to "%ISO_PATH%".
  pause
  exit /b 1
)
del "%MANIFEST_PATH%" >nul 2>nul
echo NEXUS OS ISO downloaded and verified.
goto find_qemu

:invalid_manifest
echo The release download manifest is invalid.
del "%MANIFEST_PATH%" >nul 2>nul
pause
exit /b 1

:download_failed
echo ISO download or assembly failed. Your existing ISO was left untouched.
del "%DOWNLOAD_PATH%" "%DOWNLOAD_PATH%.next" "%MANIFEST_PATH%" >nul 2>nul
del "%INSTALL_DIR%\nexus-os.iso.part-*.download" >nul 2>nul
pause
exit /b 1

:download_file
where curl.exe >nul 2>nul
if not errorlevel 1 (
  curl.exe --fail --location --retry 3 --retry-delay 2 --output "%~2" "%~1"
  exit /b %errorlevel%
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri '%~1' -OutFile '%~2'"
exit /b %errorlevel%

:find_qemu
if defined QEMU_HOME if exist "%QEMU_HOME%\qemu-system-x86_64.exe" set "QEMU_EXE=%QEMU_HOME%\qemu-system-x86_64.exe"
if defined QEMU_EXE goto run_qemu
if exist "%~dp0qemu\qemu-system-x86_64.exe" set "QEMU_EXE=%~dp0qemu\qemu-system-x86_64.exe"
if defined QEMU_EXE goto run_qemu
if exist "%LOCALAPPDATA%\Programs\QEMU\qemu-system-x86_64.exe" set "QEMU_EXE=%LOCALAPPDATA%\Programs\QEMU\qemu-system-x86_64.exe"
if defined QEMU_EXE goto run_qemu
if exist "%LOCALAPPDATA%\QEMU\qemu-system-x86_64.exe" set "QEMU_EXE=%LOCALAPPDATA%\QEMU\qemu-system-x86_64.exe"
if defined QEMU_EXE goto run_qemu
for /f "delims=" %%Q in ('where qemu-system-x86_64.exe 2^>nul') do if not defined QEMU_EXE set "QEMU_EXE=%%Q"
if defined QEMU_EXE goto run_qemu
if exist "%ProgramFiles%\qemu\qemu-system-x86_64.exe" set "QEMU_EXE=%ProgramFiles%\qemu\qemu-system-x86_64.exe"
if defined QEMU_EXE goto run_qemu
if exist "%ProgramFiles%\QEMU\qemu-system-x86_64.exe" set "QEMU_EXE=%ProgramFiles%\QEMU\qemu-system-x86_64.exe"
if defined QEMU_EXE goto run_qemu

if not defined QEMU_EXE (
  echo QEMU was not found. This launcher does not install software or request administrator access.
  echo Install or unpack a Windows QEMU build in a user-writable folder, then either:
  echo   - set QEMU_HOME to that folder,
  echo   - place it in "%LOCALAPPDATA%\Programs\QEMU", or
  echo   - place it in a "qemu" folder beside this batch file.
  echo You can also add qemu-system-x86_64.exe to your PATH.
  echo QEMU downloads: https://www.qemu.org/download/#windows
  pause
  exit /b 1
)

:run_qemu
echo Starting NEXUS OS in QEMU. The live session does not install to your disk.
echo Close the QEMU window to shut down the virtual machine.
"%QEMU_EXE%" -machine q35 -m 4096 -smp 2 -cdrom "%ISO_PATH%" -boot order=d -nic user,model=e1000
if errorlevel 1 (
  echo QEMU exited with an error.
  pause
  exit /b 1
)
exit /b 0
