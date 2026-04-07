$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$ScriptDir\..\.."
. "$ScriptDir\_colors.ps1"

Write-Host "${BLUE}${BOLD}🛠  Compiling WeOn SDK for Windows...${NC}"

Set-Location "code"
# Сборка
zig build --prefix ../bin -Dtarget=x86_64-windows -Doptimize=ReleaseFast

# Синхронизация хедеров
Write-Host "📂 Syncing headers..."
$DestInc = "../bin/include/weon"
if (!(Test-Path $DestInc)) { New-Item -ItemType Directory -Path $DestInc -Force }
Copy-Item -Path "include/weon\*" -Destination $DestInc -Recurse -Force

Write-Host "${GREEN}✅ Windows build completed.${NC}"