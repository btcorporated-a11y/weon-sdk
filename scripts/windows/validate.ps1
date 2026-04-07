$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$ScriptDir\..\.."
. "$ScriptDir\_colors.ps1"

Write-Host "${BLUE}${BOLD}🧪 Running Windows Integration Tests...${NC}"

$BIN_INC = "$(Get-Location)\bin\include"
$BIN_LIB = "$(Get-Location)\bin\windows-x86_64"
$TEST_SRC = "$(Get-Location)\tests\main.c"
$TEST_BIN = "$(Get-Location)\tests\main.exe"

zig cc "$TEST_SRC" -o "$TEST_BIN" -I"$BIN_INC" -L"$BIN_LIB" -lweon-sdk

Copy-Item "$BIN_LIB\weon-sdk.dll" "tests\" -Force
& "$TEST_BIN"

Write-Host "${GREEN}✅ Windows validation passed!${NC}"