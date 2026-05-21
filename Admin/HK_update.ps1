# --- Configuration ---
$repoZipUrl = "https://github.com/JacksonBoyle/HotKey-CMD/archive/refs/heads/main.zip"
$postUpdateScriptName = "post_update.ps1" # Name of the script to run afterward

# 1. Path Discovery
# $PSScriptRoot is the folder where this script lives
$currentDir = $PSScriptRoot
$configFile = Join-Path $currentDir "hotkeycmd_path.txt"
$postUpdateScriptPath = Join-Path $currentDir $postUpdateScriptName

if (Test-Path $configFile) {
    # Pull the saved directory from the text file
    $installPath = Get-Content -Path $configFile -Raw
    $installPath = $installPath.Trim()
} else {
    Write-Host "[!] Error: hotkeycmd_path.txt not found at $configFile" -ForegroundColor Red
    Write-Host "[*] Please run the Installer again to generate this file." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "         HOTKEY-CMD SYSTEM UPDATE              " -ForegroundColor White -BackgroundColor DarkMagenta
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "[*] Target Directory: $installPath" -ForegroundColor White

# 2. Preparation
$tempZip = Join-Path $env:TEMP "HotKeyUpdate.zip"
$extractTemp = Join-Path $env:TEMP "HotKeyUpdateExtract"

# 3. Execution
$updateSuccessful = $false
try {
    Write-Host "[*] Fetching latest version from GitHub..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip

    Write-Host "[*] Applying updates..." -ForegroundColor Yellow
    Expand-Archive -Path $tempZip -DestinationPath $extractTemp -Force

    # Handle the GitHub "main" subfolder and move files to the real install path
    $subFolder = Get-ChildItem -Path $extractTemp | Select-Object -First 1
    Copy-Item -Path "$($subFolder.FullName)\*" -Destination $installPath -Recurse -Force

    Write-Host "`n[!] Update Successful!" -ForegroundColor Green
    $updateSuccessful = $true
}
catch {
    Write-Host "`n[!] Update Failed: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # 4. Cleanup
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
}

# 5. Post-Update Execution Block
if ($updateSuccessful) {
    if (Test-Path $postUpdateScriptPath) {
        Write-Host "[*] Launching post-update task: $postUpdateScriptName..." -ForegroundColor Order
        
        # Runs the script silently in the background using your preferred style
        Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$postUpdateScriptPath`""
    } else {
        Write-Host "[!] Warning: Post-update script not found at $postUpdateScriptPath" -ForegroundColor Yellow
    }
}

Write-Host "`nAll files are up to date." -ForegroundColor Gray
Sleep 3
