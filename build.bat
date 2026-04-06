@echo off
setlocal enabledelayedexpansion

echo 🚀 Starting WeOn SDK Build ^& Validation (Windows Mode)...

:: Пути
set "ROOT_DIR=%cd%"
set "CODE_DIR=%ROOT_DIR%\code"
set "BIN_DIR=%ROOT_DIR%\bin"
set "SOURCE_INCLUDE=%CODE_DIR%\include\weon"
set "TEST_DIR=%ROOT_DIR%\tests"

:: 1. Очистка
echo 🧹 Cleaning bin and zig-cache...
if exist "%BIN_DIR%" rd /s /q "%BIN_DIR%"
if exist "%CODE_DIR%\.zig-cache" rd /s /q "%CODE_DIR%\.zig-cache"
if exist "%CODE_DIR%\zig-out" rd /s /q "%CODE_DIR%\zig-out"
mkdir "%BIN_DIR%"

:: 2. Сборка бинарников
cd /d "%CODE_DIR%"

echo 🐧 Building Linux x86_64 (Standard GNU ABI)...
zig build --prefix ../bin -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseFast
if %errorlevel% neq 0 exit /b %errorlevel%

echo 🪟 Building Windows x86_64...
zig build --prefix ../bin -Dtarget=x86_64-windows -Doptimize=ReleaseFast
if %errorlevel% neq 0 exit /b %errorlevel%

:: 3. Организация общей папки include
echo 📦 Packaging shared headers...
mkdir "%BIN_DIR%\include\weon"
xcopy /E /I /Y "%SOURCE_INCLUDE%" "%BIN_DIR%\include\weon" >nul

:: 4. ВАЛИДАЦИЯ (Авто-тест для Windows)
echo 🧪 Running Integration Tests (MSVC/MinGW)...

:: Компилируем тест. 
:: Если у тебя установлен GCC (MinGW), используем его. 
:: Если только MSVC (cl.exe), команду нужно будет заменить.
gcc "%TEST_DIR%\main.c" -o "%TEST_DIR%\main.exe" -I"%BIN_DIR%\include" -L"%BIN_DIR%\windows-x86_64" -lweon-sdk

if %errorlevel% neq 0 (
    echo ❌ Test Compilation Failed
    exit /b %errorlevel%
)

:: Запускаем тест
cd /d "%ROOT_DIR%"
"%TEST_DIR%\main.exe"

if %errorlevel% neq 0 (
    echo ❌ SDK Validation Failed!
    exit /b %errorlevel%
)

echo ------------------------------------------------
echo ✅ SDK Bundle Validated ^& Ready!
echo 📍 Location: %BIN_DIR%
echo ------------------------------------------------

pause