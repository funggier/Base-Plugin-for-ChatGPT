@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Refresh-PluginName.ps1"
set CODE=%ERRORLEVEL%
echo.
if not "%CODE%"=="0" echo Refresh failed with exit code %CODE%.
pause
exit /b %CODE%
