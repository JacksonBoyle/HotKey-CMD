# ==============================================================================
# Project: HotKey-CMD Installer
# Author: Jackson Boyle
# Description: Downloads, flattens, and installs the HotKey-CMD suite from GitHub.
# ==============================================================================

# --- Configuration ---
$repoZipUrl = "https://github.com/JacksonBoyle/HotKey-CMD/archive/refs/heads/main.zip"

# --- Functions ---

function Get-UserPathWithGUI {
    <#
    .SYNOPSIS
        Displays a graphical folder picker to define the installation target.
    #>
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Form Window Setup
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "HotKey-CMD Installer"
    $form.Size = New-Object System.Drawing.Size(500,200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.Topmost = $true

    # UI Elements: Instruction Label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20,20)
    $label.Size = New-Object System.Drawing.Size(400,20)
    $label.Text = "Select or type the installation location:"
    $form.Controls.Add($label)

    # UI Elements: Path Input Field
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20,50)
    $textBox.Size = New-Object System.Drawing.Size(350,20)
    $textBox.Text = "C:\HotKey-CMD" 
    $form.Controls.Add($textBox)

    # UI Elements: Directory Browser Button
    $browseBtn = New-Object System.Windows.Forms.Button
    $browseBtn.Location = New-Object System.Drawing.Point(380,48)
    $browseBtn.Size = New-Object System.Drawing.Size(80,25)
    $browseBtn.Text = "Browse..."
    $browseBtn.Add_Click({
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
        $FileBrowser.Title = "Select Folder"
        $FileBrowser.CheckFileExists = $false
        $FileBrowser.FileName = "Select Folder Here"
        if ($FileBrowser.ShowDialog() -eq "OK") {
            $textBox.Text = Split-Path -Path $FileBrowser.FileName
        }
    })
    $form.Controls.Add($browseBtn)

    # UI Elements: Confirm Install Button
    $installBtn = New-Object System.Windows.Forms.Button
    $installBtn.Location = New-Object System.Drawing.Point(150,110)
    $installBtn.Size = New-Object System.Drawing.Size(100,30)
    $installBtn.Text = "Install"
    $installBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($installBtn)

    # Execute GUI
    $result = $form.ShowDialog()

    if ($result -eq "OK") {
        return $textBox.Text
    } else {
        Write-Host "[!] Installation cancelled by user." -ForegroundColor Red
        exit
    }
}

# --- Main Execution ---

Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "          HOTKEY-CMD GUI INSTALLER             " -ForegroundColor White -BackgroundColor Blue
Write-Host "===============================================" -ForegroundColor Cyan

# STEP 1: Define and Create Target Directories
$userTarget = Get-UserPathWithGUI
Write-Host "[*] Preparing: $userTarget" -ForegroundColor Green

if (-not (Test-Path $userTarget)) {
    New-Item -ItemType Directory -Path $userTarget -Force | Out-Null
}

# STEP 2: Configure "User Data" (Local-Only Settings)
# Note: This folder is kept out of the GitHub repo to preserve local config.
$userDataDir = Join-Path $userTarget "User Data"
if (-not (Test-Path $userDataDir)) {
    New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
}

# Save installation path to TXT file for the Updater to pull later
$configFilePath = Join-Path $userDataDir "hotkeycmd_path.txt"
$userTarget | Out-File -FilePath $configFilePath -Encoding utf8
Write-Host "[*] Path saved for updates: $configFilePath" -ForegroundColor Gray

# STEP 3: Download and Extract Repository
$tempZip = Join-Path $env:TEMP "HotKeyDownload.zip"
$extractTemp = Join-Path $env:TEMP "HotKeyExtract"

Write-Host "[*] Fetching latest files from GitHub..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip

Write-Host "[*] Extracting and flattening structure..." -ForegroundColor Yellow

# Initial extraction to temp location
if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
Expand-Archive -Path $tempZip -DestinationPath $extractTemp -Force

# Locate the root folder inside the ZIP (e.g., HotKey-CMD-main)
$subFolder = Get-ChildItem -Path $extractTemp | Select-Object -First 1

# Move files to final destination (skipping the nested GitHub folder)
Copy-Item -Path "$($subFolder.FullName)\*" -Destination $userTarget -Recurse -Force

# STEP 4: Finalize and Cleanup
Remove-Item $tempZip -Force
Remove-Item $extractTemp -Recurse -Force

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host " [!] Success! HotKey-CMD is now installed. " -ForegroundColor Green
Write-Host " Target: $userTarget" -ForegroundColor White
Write-Host "===============================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
