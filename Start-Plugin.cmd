@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Plugin.ps1"
set CODE=%ERRORLEVEL%
echo.
if not "%CODE%"=="0" echo Start failed with exit code %CODE%.
pause
exit /b %CODE%
