#!/bin/bash

set -e

echo "🚀 Starting WeOn SDK Build & Validation..."

# Пути
ROOT_DIR=$(pwd)
CODE_DIR="$ROOT_DIR/code"
BIN_DIR="$ROOT_DIR/bin"
SOURCE_INCLUDE="$CODE_DIR/include/weon"
TEST_DIR="$ROOT_DIR/tests"

# 1. Очистка
echo "🧹 Cleaning bin and zig-cache..."
rm -rf "$BIN_DIR"
rm -rf "$CODE_DIR/.zig-cache"
rm -rf "$CODE_DIR/zig-out"
mkdir -p "$BIN_DIR"

# 2. Сборка бинарников
cd "$CODE_DIR"

echo "🐧 Building Linux x86_64 (Standard GNU ABI)..."
zig build --prefix ../bin -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseFast

echo "🪟 Building Windows x86_64..."
zig build --prefix ../bin -Dtarget=x86_64-windows -Doptimize=ReleaseFast

# 3. Организация общей папки include
echo "📦 Packaging shared headers..."
mkdir -p "$BIN_DIR/include/weon"
cp -r "$SOURCE_INCLUDE/." "$BIN_DIR/include/weon/"

# 4. ВАЛИДАЦИЯ (Авто-тест)
echo "🧪 Running Integration Tests..."

# Компилируем тест, используя только что собранные хедеры
gcc "$TEST_DIR/main.c" -o "$TEST_DIR/main" -ldl -I"$BIN_DIR/include"

# Запускаем тест. Если он вернет не 0, скрипт прервется благодаря set -e
cd "$ROOT_DIR"
./tests/main

echo "------------------------------------------------"
echo "✅ SDK Bundle Validated & Ready!"
echo "📍 Location: $BIN_DIR"
echo "------------------------------------------------"