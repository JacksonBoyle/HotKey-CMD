# --- HotKey-CMD Auto-Installer (PowerShell) ---
$repoZipUrl = "https://github.com/JacksonBoyle/HotKey-CMD/archive/refs/heads/main.zip"

Clear-Host
Write-Host "--- HotKey-CMD Installation Utility ---" -ForegroundColor Cyan

# 1. Ask user for the destination
$userTarget = Read-Host "Where should I install the scripts? (e.g. C:\HotKey-CMD)"
if ([string]::IsNullOrWhiteSpace($userTarget)) {
    $userTarget = "$HOME\Desktop\HotKey-CMD"
}

# 2. Create directory if it doesn't exist
if (-not (Test-Path $userTarget)) {
    New-Item -ItemType Directory -Path $userTarget -Force | Out-Null
    Write-Host "[+] Created folder: $userTarget" -ForegroundColor Gray
}

# 3. Define temporary zip location
$tempZip = Join-Path $env:TEMP "HotKeyDownload.zip"

# 4. Download
Write-Host "[*] Downloading from GitHub..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip

# 5. Extract
Write-Host "[*] Extracting files to $userTarget..." -ForegroundColor Yellow
Expand-Archive -Path $tempZip -DestinationPath $userTarget -Force

# 6. Clean up the zip file
Remove-Item $tempZip -Force
Write-Host "[!] Success! Your scripts are ready in $userTarget" -ForegroundColor Green

Read-Host "Press Enter to exit"