#!/bin/bash
set -e

# Подключаем цвета для красивого старта
source "scripts/linux/_colors.sh"

echo "${BOLD}${BLUE}🚀 WeOn SDK Master Build (Linux Pipeline)${NC}"
echo "------------------------------------------------"

# 1. Очистка старых артефактов
echo "🧹 Cleaning up..."
rm -rf bin/ code/.zig-cache/ tests/main

# 2. Последовательный запуск модулей
bash scripts/linux/build_lib.sh
bash scripts/linux/validate.sh
bash scripts/linux/install.sh

echo "------------------------------------------------"
echo "${BOLD}${GREEN}🏁 SUCCESS: WeOn SDK is built, tested and installed!${NC}"
echo "------------------------------------------------"