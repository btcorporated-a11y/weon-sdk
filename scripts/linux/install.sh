#!/bin/bash
set -e
cd "$(dirname "$0")/../../"
source "scripts/linux/_colors.sh"

echo "${YELLOW}${BOLD}⚙️  Installing WeOn SDK to system...${NC}"

LIB_DEST="/usr/local/lib/weon"
INC_DEST="/usr/local/include/weon"
CONF_PATH="/etc/ld.so.conf.d/weon.conf"

sudo rm -rf "$LIB_DEST" "$INC_DEST"
sudo mkdir -p "$LIB_DEST" "$INC_DEST"

sudo cp bin/linux-x86_64/weon-sdk.so "$LIB_DEST/"
sudo cp -r bin/include/weon/. "$INC_DEST/"

echo "$LIB_DEST" | sudo tee "$CONF_PATH" > /dev/null
sudo ldconfig

echo "${GREEN}${BOLD}✅ Installation complete!${NC}"
echo "🔹 Headers: $INC_DEST"
echo "🔹 Binary:  $LIB_DEST/weon-sdk.so"