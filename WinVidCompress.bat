@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SCRIPT=%~dp0WinVidCompress.ps1"

REM Double-click = TUI
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
  goto :eof
)

REM Drag & drop file(s)/folder(s) = queue and process
set "ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%" !ARGS!


