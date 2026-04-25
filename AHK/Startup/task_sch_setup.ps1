# --- 1. Elevation Block (Self-Elevate to Admin) ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrative privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. Path Logic ---
$CurrentDir = $PSScriptRoot
$VBSName = "Startup_ahk.VBS"
$FullVBSPath = Join-Path -Path $CurrentDir -ChildPath $VBSName

if (-not (Test-Path $FullVBSPath)) {
    Write-Error "Could not find $VBSName in $CurrentDir"
    Pause
    exit
}

# --- 3. Define Task Details ---
$TaskName = "Hotkey_CMD_Startup"
$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$FullVBSPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogon
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

# --- 4. Register the Task ---
try {
    Register-ScheduledTask -TaskName $TaskName `
                           -Action $Action `
                           -Trigger $Trigger `
                           -Settings $Settings `
                           -RunLevel Highest `
                           -Force
    Write-Host "`n--- Success: Task Created Successfully ---" -ForegroundColor Green
    Write-Host "Target: $FullVBSPath" -ForegroundColor Cyan
}
catch {
    Write-Host "`n--- Error: Failed to register task ---" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor White
}

Write-Host "`nPress any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")