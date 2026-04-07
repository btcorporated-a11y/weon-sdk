#!/bin/bash
set -e
cd "$(dirname "$0")/../../"
source "scripts/linux/_colors.sh"

echo "${BLUE}${BOLD}🧪 Running Integration Tests...${NC}"

BIN_INC="$(pwd)/bin/include"
BIN_LIB="$(pwd)/bin/linux-x86_64"
TEST_SRC="$(pwd)/tests/main.c"
TEST_BIN="$(pwd)/tests/main"

gcc "$TEST_SRC" -o "$TEST_BIN" -ldl -I"$BIN_INC"

LD_LIBRARY_PATH="$BIN_LIB" "$TEST_BIN"

echo "${GREEN}✅ Validation passed!${NC}"