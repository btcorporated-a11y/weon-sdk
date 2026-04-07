#!/bin/bash
set -e
# Переходим в корень проекта (на 2 уровня вверх от скрипта)
cd "$(dirname "$0")/../../"
source "scripts/linux/_colors.sh"

echo "${BLUE}${BOLD}🛠  Compiling WeOn SDK...${NC}"

cd code
# Сборка под обе платформы
echo "📦 Building Linux x86_64..."
zig build --prefix ../bin -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseFast

echo "📦 Building Windows x86_64..."
zig build --prefix ../bin -Dtarget=x86_64-windows -Doptimize=ReleaseFast

# Синхронизация публичных хедеров
echo "📂 Syncing headers..."
mkdir -p ../bin/include/weon
cp -r include/weon/. ../bin/include/weon/

echo "${GREEN}✅ Build completed successfully.${NC}"