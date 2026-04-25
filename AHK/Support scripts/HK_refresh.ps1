$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 1. Define the Base Path ---
# This gets the folder "C:\HotKey command" by going up 2 levels
$ProjectRoot = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\")

# --- 2. Construct Relative Paths to the targets ---
$Script1 = Join-Path -Path $ProjectRoot -ChildPath "Admin\HK_kill.ps1"
$Script2 = Join-Path -Path $ProjectRoot -ChildPath "AHK\Startup\Startup_ahk.ps1"

# --- 3. Run Script 1 (The Killer) and WAIT ---
Write-Host "Running Kill Script: $Script1" -ForegroundColor Cyan
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Script1`"" -Wait

# --- 4. Run Script 2 (The Startup) ---
# We usually don't use -Wait here so the master script can close while the startup scripts stay open
Write-Host "Kill complete. Launching Startup Script: $Script2" -ForegroundColor Green
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Script2`""

Write-Host "Refresh sequence finished." -ForegroundColor Yellow
#Start-Sleep -Seconds 0
