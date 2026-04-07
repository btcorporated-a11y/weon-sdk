#!/bin/bash
set -e
cd "$(dirname "$0")/../../"
source "scripts/linux/_colors.sh"

echo "${YELLOW}${BOLD}⚙️  Installing WeOn SDK to system...${NC}"

# Настройки путей
LIB_DEST="/usr/local/lib/weon"
INC_DEST="/usr/local/include/weon"
CONF_PATH="/etc/ld.so.conf.d/weon.conf"

# 1. Очистка и создание директорий
sudo rm -rf "$LIB_DEST" "$INC_DEST"
sudo mkdir -p "$LIB_DEST" "$INC_DEST"

# 2. Копирование файлов
sudo cp bin/linux-x86_64/weon-sdk.so "$LIB_DEST/"
sudo cp -r bin/include/weon/. "$INC_DEST/"

# 3. Регистрация в системе
echo "$LIB_DEST" | sudo tee "$CONF_PATH" > /dev/null
sudo ldconfig

echo "${GREEN}${BOLD}✅ Installation complete!${NC}"
echo "🔹 Headers: $INC_DEST"
echo "🔹 Binary:  $LIB_DEST/weon-sdk.so"