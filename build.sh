#!/bin/bash
set -e

source "scripts/linux/_colors.sh"

echo "${BOLD}${BLUE}🚀 WeOn SDK Master Build (Linux Pipeline)${NC}"
echo "------------------------------------------------"

echo "🧹 Cleaning up..."
rm -rf bin/ code/.zig-cache/ tests/main

bash scripts/linux/build_lib.sh
bash scripts/linux/validate.sh
bash scripts/linux/install.sh

echo "------------------------------------------------"
echo "${BOLD}${GREEN}🏁 SUCCESS: WeOn SDK is built, tested and installed!${NC}"
echo "------------------------------------------------"