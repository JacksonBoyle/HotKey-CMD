# ==============================================================================
# Script: preupdate.ps1
# Location: C:\HotKey command\Admin\
# Description: Checks connectivity, provides help link on failure, and relocates assets.
# ==============================================================================

# 1. Define Paths and URLs
$sourceDir = $PSScriptRoot
$targetDir = Join-Path $sourceDir "..\User Data"
$repoZipUrl = "https://github.com/JacksonBoyle/HotKey-CMD/archive/refs/heads/main.zip"
$helpUrl    = "https://github.com/JacksonBoyle/HotKey-CMD"

# File Sources
$updateSource = Join-Path $sourceDir "HK_update.ps1"
$configSource = Join-Path $sourceDir "..\Library\Main config\config.csv"
$versionSource = Join-Path $sourceDir "version.txt"

# 2. Connectivity Check (Updated for Security)
Write-Host "[*] Verifying connection to GitHub..." -ForegroundColor Cyan
try {
    # Added -UseBasicParsing to prevent the warning in image_bf305f.png
    $response = Invoke-WebRequest -Uri $repoZipUrl -Method Head -TimeoutSec 5 -ErrorAction Stop -UseBasicParsing
    Write-Host " [+] Connection verified." -ForegroundColor Green
}
catch {
    Write-Host "`n [!] Error: No internet connection or GitHub is unreachable." -ForegroundColor Red
    Write-Host " [!] Please resolve your connection issue and try again." -ForegroundColor Yellow
    Write-Host " [!] Manual Help/Download: $helpUrl" -ForegroundColor Cyan
    
    Write-Host "`n [!] Update aborted." -ForegroundColor Red
    Pause
    exit
}

# 3. Execution logic (File Relocation)
Write-Host "`n[*] Starting file relocation..." -ForegroundColor Cyan

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
}

# Copy version.txt
if (Test-Path $versionSource) {
    Copy-Item -Path $versionSource -Destination $targetDir -Force
    Write-Host " [+] Relocated: version.txt" -ForegroundColor Green
}

# 4. Launch the Update
Write-Host "`n[*] Launching update process from User Data..." -ForegroundColor Magenta
Set-Location -Path $targetDir

if (Test-Path ".\HK_update.ps1") {
    & ".\HK_update.ps1"
}
