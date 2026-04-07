$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$ScriptDir\..\.."
. "$ScriptDir\_colors.ps1"

Write-Host "${YELLOW}${BOLD}⚙️  Installing WeOn SDK to System (Program Files)...${NC}"

$INSTALL_ROOT = "C:\Program Files\weon"
$LIB_DEST = "$INSTALL_ROOT\lib"
$INC_DEST = "$INSTALL_ROOT\include"

# Проверка прав администратора
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "${RED}❌ Error: Please run this script as Administrator!${NC}"
    exit 1
}

# Очистка и создание директорий
if (Test-Path $INSTALL_ROOT) { Remove-Item -Path $INSTALL_ROOT -Recurse -Force }
New-Item -ItemType Directory -Path $LIB_DEST -Force
New-Item -ItemType Directory -Path $INC_DEST -Force

# Копирование
Copy-Item "bin\windows-x86_64\*" -Destination $LIB_DEST -Force
Copy-Item -Path "bin\include\weon" -Destination $INC_DEST -Recurse -Force

Write-Host "${GREEN}${BOLD}✅ Installation complete!${NC}"
Write-Host "🔹 Location: $INSTALL_ROOT"
Write-Host "${YELLOW}ℹ️  Don't forget to add '$LIB_DEST' to your PATH environment variable.${NC}"