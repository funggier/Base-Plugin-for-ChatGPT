@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Status-Plugin.ps1"
set CODE=%ERRORLEVEL%
echo.
pause
exit /b %CODE%
