@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "SCRIPT=%~dp0WinVidCompress.ps1"
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%SCRIPT%" goto missing_script
if not exist "%POWERSHELL%" goto missing_powershell

REM Empty arguments open the menu; selections pass directly to PowerShell.
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%" %*
set "LAUNCH_EXIT=%ERRORLEVEL%"
if not "%LAUNCH_EXIT%"=="0" goto launch_failed
exit /b 0

:missing_script
echo WinVidCompress: cannot find "%SCRIPT%". 1>&2
echo Keep WinVidCompress.bat and WinVidCompress.ps1 in the same folder. 1>&2
pause
exit /b 2

:missing_powershell
echo WinVidCompress: cannot find Windows PowerShell at "%POWERSHELL%". 1>&2
echo Check that Windows PowerShell 5.1 is available on this Windows installation. 1>&2
pause
exit /b 2

:launch_failed
echo WinVidCompress: PowerShell returned error %LAUNCH_EXIT%. Review the diagnostic above. 1>&2
echo Check access to WinVidCompress.ps1 and Windows PowerShell. 1>&2
pause
exit /b %LAUNCH_EXIT%
