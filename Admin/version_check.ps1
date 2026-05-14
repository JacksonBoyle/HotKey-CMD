# ==============================================================================
# Script: version_check.ps1
# Description: Logs the specific version string if an update is found.
# ==============================================================================

# 1. Configuration
$repoRawUrl = "https://raw.githubusercontent.com/JacksonBoyle/HotKey-CMD/main/Admin/version.txt"

# Define the status file in the SAME folder as this script
$statusOutputFile = Join-Path $PSScriptRoot "update_available.txt"

# 2. Get the local installation path to find the current version.txt
$configPath = "$PSScriptRoot\..\User Data\hotkeycmd_path.txt"

if (Test-Path $configPath) {
    $installPath = (Get-Content -Path $configPath -Raw).Trim()
    $localVersionFile = Join-Path $installPath "Admin\version.txt"
} else {
    Write-Host "[!] Error: Installation path config not found." -ForegroundColor Red
    exit
}

# 3. Execution
try {
    Write-Host "[*] Checking for updates..." -ForegroundColor Cyan
    
    # Fetch the latest version string from GitHub (e.g., V1.1)
    $onlineVersion = (Invoke-RestMethod -Uri $repoRawUrl).Trim()
    
    # Read the local version string
    if (Test-Path $localVersionFile) {
        $localVersion = (Get-Content -Path $localVersionFile -Raw).Trim()
        
        Write-Host " [+] Local Version:  $localVersion"
        Write-Host " [+] Online Version: $onlineVersion" -ForegroundColor Yellow

        if ($localVersion -eq $onlineVersion) {
            Write-Host "`n[!] Your system is up to date." -ForegroundColor Green
            # Write "no" if they match
            "no" | Out-File -FilePath $statusOutputFile -Encoding utf8 -Force
        } else {
            Write-Host "`n[!] UPDATE AVAILABLE: $onlineVersion" -ForegroundColor Red
            # Write the actual version string (V1.2, etc.) to the file
            $onlineVersion | Out-File -FilePath $statusOutputFile -Encoding utf8 -Force
        }
    } else {
        Write-Host "[!] Error: Local version.txt not found." -ForegroundColor Red
        "no" | Out-File -FilePath $statusOutputFile -Encoding utf8 -Force
    }
}
catch {
    Write-Host "[!] Error: Could not connect to GitHub." -ForegroundColor Red
    "no" | Out-File -FilePath $statusOutputFile -Encoding utf8 -Force
}

Write-Host "[*] Status saved to: $statusOutputFile" -ForegroundColor Gray
Sleep 2