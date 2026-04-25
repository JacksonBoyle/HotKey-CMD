# --- 1. Admin Elevation ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. Define the Target Folders ---
# We create a list (array) of the relative paths you want to scan
$RelativePaths = @(
    "..\Main scripts",
    "..\Personal scripts"
)

Write-Host "--- Starting AHK Script Manager ---" -ForegroundColor Cyan

# --- 3. Loop through each folder ---
foreach ($Path in $RelativePaths) {
    $TargetFolder = Join-Path -Path $PSScriptRoot -ChildPath $Path
    $ResolvedPath = Resolve-Path $TargetFolder -ErrorAction SilentlyContinue

    if ($ResolvedPath) {
        Write-Host "`nScanning folder: $($ResolvedPath.Path)" -ForegroundColor Yellow
        $Files = Get-ChildItem -Path $ResolvedPath.Path -Filter *.ahk

        if ($Files.Count -eq 0) {
            Write-Host "  No .ahk files found here." -ForegroundColor Gray
        }

        foreach ($File in $Files) {
            Write-Host "  Launching: $($File.Name)" -ForegroundColor Green
            # Ensure AutoHotkey.exe is in your PATH, otherwise use full C:\ path
            Start-Process "AutoHotkey.exe" -ArgumentList """$($File.FullName)"""
        }
    } else {
        Write-Host "`nERROR: Folder not found: $Path" -ForegroundColor Red
    }
}

Write-Host "`n--- All tasks complete ---" -ForegroundColor Cyan
#Start-Sleep -Seconds 2 # Brief pause to see results before window closes
