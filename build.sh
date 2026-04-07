#!/bin/bash

set -e

# Цвета (используем синтаксис Bash для спецсимволов)
GREEN=$'\e[32m'
RED=$'\e[31m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
NC=$'\e[0m' # No Color (Сброс)

echo -e "${GREEN}🚀 Starting WeOn SDK Build & Validation...${NC}"

# Пути
ROOT_DIR=$(pwd)
CODE_DIR="$ROOT_DIR/code"
BIN_DIR="$ROOT_DIR/bin"
SOURCE_INCLUDE="$CODE_DIR/include/weon"
TEST_DIR="$ROOT_DIR/tests"

# Системные пути для установки
INSTALL_LIB_DIR="/usr/local/lib/weon"
INSTALL_INC_DIR="/usr/local/include/weon"
LD_CONF_FILE="/etc/ld.so.conf.d/weon.conf"

# 1. Очистка локальной сборки
echo "🧹 Cleaning local bin and zig-cache..."
rm -rf "$BIN_DIR"
rm -rf "$CODE_DIR/.zig-cache"
mkdir -p "$BIN_DIR"

# 2. Сборка бинарников
cd "$CODE_DIR"
echo "🐧 Building Linux x86_64..."
zig build --prefix ../bin -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseFast
echo "🪟 Building Windows x86_64..."
zig build --prefix ../bin -Dtarget=x86_64-windows -Doptimize=ReleaseFast

# 3. Упаковка хедеров
echo "📦 Packaging shared headers..."
mkdir -p "$BIN_DIR/include/weon"
cp -r "$SOURCE_INCLUDE/." "$BIN_DIR/include/weon/"

# 4. ВАЛИДАЦИЯ (Авто-тест)
echo "🧪 Running Integration Tests..."
gcc "$TEST_DIR/main.c" -o "$TEST_DIR/main" -ldl -I"$BIN_DIR/include"
cd "$ROOT_DIR"
./tests/main

echo -e "${GREEN}✅ Integration Test Passed!${NC}"

# 5. СИСТЕМНАЯ УСТАНОВКА (Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "⚙️  Installing SDK to system paths (requires sudo)..."

    # Удаляем старую установку и создаем чистые папки
    sudo rm -rf "$INSTALL_LIB_DIR"
    sudo rm -rf "$INSTALL_INC_DIR"
    sudo mkdir -p "$INSTALL_LIB_DIR"
    sudo mkdir -p "$INSTALL_INC_DIR"

    # Копируем библиотеку и заголовки
    sudo cp "$BIN_DIR/linux-x86_64/weon-sdk.so" "$INSTALL_LIB_DIR/"
    sudo cp -r "$BIN_DIR/include/weon/." "$INSTALL_INC_DIR/"

    # Обновляем конфигурацию линковщика (ldconfig)
    echo "📝 Updating ld.so configuration..."
    echo "$INSTALL_LIB_DIR" | sudo tee "$LD_CONF_FILE" > /dev/null
    
    # Заставляем систему перечитать кэш библиотек
    sudo ldconfig

    echo -e "${GREEN}✅ System installation complete!${NC}"
    echo "📍 Headers: $INSTALL_INC_DIR"
    echo "📍 Library: $INSTALL_LIB_DIR"
else
    echo "⚠️  System installation skipped (not a Linux system)."
fi

echo "------------------------------------------------"
echo -e "${GREEN}🏁 SDK is ready and installed!${NC}"
echo "------------------------------------------------"