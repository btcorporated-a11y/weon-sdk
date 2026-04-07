@echo off
echo 🚀 Starting WeOn SDK Master Build (Windows Pipeline)

:: Запуск PowerShell скриптов по очереди
powershell -ExecutionPolicy Bypass -File scripts\windows\build_lib.ps1
if %errorlevel% neq 0 exit /b %errorlevel%

powershell -ExecutionPolicy Bypass -File scripts\windows\validate.ps1
if %errorlevel% neq 0 exit /b %errorlevel%

powershell -ExecutionPolicy Bypass -File scripts\windows\install.ps1
if %errorlevel% neq 0 exit /b %errorlevel%

echo ✅ SUCCESS: WeOn SDK is built and installed!
pause