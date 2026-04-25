# --- 1. Admin Elevation ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. Define the Root Directory ---
# Going up 1 level from \Admin\ to \HotKey command\
$BaseDir = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..")).Path

Write-Host "--- Scanning for scripts inside: $BaseDir ---" -ForegroundColor Cyan

# --- 3. Use Get-CimInstance for deeper inspection ---
$AllProcesses = Get-CimInstance Win32_Process

foreach ($Proc in $AllProcesses) {
    # 1. Skip the current script process (HK_kill)
    if ($Proc.ProcessId -eq $PID) { continue }

    # 2. EXCLUSION: Skip the refresh script so it can finish its sequence
    if ($Proc.CommandLine -like "*HK_refresh*") {
        Write-Host "Skipping Protected Script: HK_refresh" -ForegroundColor Yellow
        continue
    }

    # 3. Check if the process belongs to your HotKey folder
    $InFolder = ($Proc.ExecutablePath -like "$BaseDir*") -or ($Proc.CommandLine -like "*$BaseDir*")
    
    if ($InFolder) {
        # Identify if it's a script runner or a script file
        $IsTarget = ($Proc.Name -match "AutoHotkey|powershell|pwsh|cmd|wscript|cscript") -or 
                    ($Proc.CommandLine -match "\.ahk|\.ps1|\.vbs|\.bat")

        if ($IsTarget) {
            Write-Host "Stopping: $($Proc.Name) [ID: $($Proc.ProcessId)]" -ForegroundColor Red
            Stop-Process -Id $Proc.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n--- Cleanup Complete ---" -ForegroundColor Green
#Start-Sleep -Seconds 2
