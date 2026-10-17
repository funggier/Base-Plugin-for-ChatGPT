@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Clear-PluginSettings.ps1"
set CODE=%ERRORLEVEL%
echo.
pause
exit /b %CODE%
