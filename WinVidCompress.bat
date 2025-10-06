@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SCRIPT=%~dp0WinVidCompress.ps1"

:: Double-click = TUI
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
  goto :eof
)

:: Drag & drop = pass all args verbatim (handles % safely via delayed expansion)
set "ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%" !ARGS!