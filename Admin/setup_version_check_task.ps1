# ==============================================================================
# Script: setup_version_check_task.ps1
# Location: C:\HKV1\Admin\
# Description: Two-task deployment strategy for bulletproof scheduling.
# ==============================================================================

# --- 1. Elevation Block (Self-Elevate to Admin) ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrative privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. Path Logic ---
$AdminDir = $PSScriptRoot
$VBSName = "version_check.vbs"
$FullVBSPath = Join-Path -Path $AdminDir -ChildPath $VBSName

# Safety Path Validation
if (-not (Test-Path $FullVBSPath)) {
    Write-Error "Could not find $VBSName at: $FullVBSPath"
    Pause
    exit
}

# --- 3. Shared Task Actions and Settings ---
$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$FullVBSPath`""
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0


# ==============================================================================
# APPROACH A: The 30-Minute Post-Login Task
# ==============================================================================
$TaskName1 = "Hotkey_CMD_version_check_login"

# Uses a native CimInstance delay format that doesn't trigger cmdlet bugs
$Trigger1 = New-ScheduledTaskTrigger -AtLogon
$Trigger1.Delay = "PT30M" # PT30M = Period Time 30 Minutes

try {
    Register-ScheduledTask -TaskName $TaskName1 `
                           -Action $Action `
                           -Trigger $Trigger1 `
                           -Settings $Settings `
                           -RunLevel Highest `
                           -Force
    Write-Host "Success: Registered Post-Login Task ($TaskName1)" -ForegroundColor Green
}
catch {
    Write-Host "Error: Failed to register task $TaskName1" -ForegroundColor Red
}


# ==============================================================================
# APPROACH B: The Daily Recurring Task (Runs at Noon, repeats every 24 hours)
# ==============================================================================
$TaskName2 = "Hotkey_CMD_version_check_daily"

# Triggers every single day at 12:00 PM
$Trigger2 = New-ScheduledTaskTrigger -Daily -At "12:00 PM"

try {
    Register-ScheduledTask -TaskName $TaskName2 `
                           -Action $Action `
                           -Trigger $Trigger2 `
                           -Settings $Settings `
                           -RunLevel Highest `
                           -Force
    Write-Host "Success: Registered Daily Repeating Task ($TaskName2)" -ForegroundColor Green
}
catch {
    Write-Host "Error: Failed to register task $TaskName2" -ForegroundColor Red
}


# --- Finalization Status ---
Write-Host "`n--- Setup Complete: Both update routines are now active ---" -ForegroundColor Cyan
Write-Host "Target VBS: $FullVBSPath" -ForegroundColor Gray
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")