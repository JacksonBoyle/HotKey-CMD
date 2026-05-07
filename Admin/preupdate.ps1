# ==============================================================================
# Script: preupdate.ps1
# Location: C:\HotKey command\Admin\
# Description: Copies the Update script and Config CSV to User Data via relative paths.
# ==============================================================================

# 1. Define Paths (Relative to the Admin folder)
$sourceDir = $PSScriptRoot

# Targets
$targetDir = Join-Path $sourceDir "..\User Data"

# File Sources
$updateSource = Join-Path $sourceDir "HK_update.ps1"
$configSource = Join-Path $sourceDir "..\Library\Main config\config.csv"

# 2. Execution logic
Write-Host "[*] Starting file relocation..." -ForegroundColor Cyan

# Ensure the destination exists
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# Copy HK_update.ps1
if (Test-Path $updateSource) {
    Copy-Item -Path $updateSource -Destination $targetDir -Force
    Write-Host " [+] Relocated: HK_update.ps1" -ForegroundColor Green
}

# Copy config.csv
if (Test-Path $configSource) {
    Copy-Item -Path $configSource -Destination $targetDir -Force
    Write-Host " [+] Relocated: config.csv" -ForegroundColor Green
} else {
    Write-Host " [!] Warning: Could not find config.csv at $configSource" -ForegroundColor Yellow
}

# 3. Launch the Update
Write-Host "`n[*] Launching update process from User Data..." -ForegroundColor Magenta
Set-Location -Path $targetDir

if (Test-Path ".\HK_update.ps1") {
    & ".\HK_update.ps1"
}