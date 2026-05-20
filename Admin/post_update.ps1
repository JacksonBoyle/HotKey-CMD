# ==============================================================================
# Script: Smart_Update_Log.ps1 (PowerShell)
# Description: Compares local version to GitHub CSV and only displays *newer* logs.
#              If no new updates exist, it exits completely silently.
# ==============================================================================

# 1. Define Local Paths and GitHub URLs relative to this script's directory
$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LocalVersionFile = Join-Path $ScriptDir "..\User Data\version.txt"
$GitHubWebURL     = "https://github.com/JacksonBoyle/HotKey-CMD/blob/main/Admin/HK_Version_History.csv"

# Create COM object for displaying clean Windows popups
$wshShell = New-Object -ComObject WScript.Shell

# Safety Check: Verify the local version file exists before proceeding
if (-not (Test-Path $LocalVersionFile)) {
    $wshShell.Popup("Local version.txt file not found at:`n$LocalVersionFile", 0, "Error", 16) | Out-Null
    Exit
}

# Read local version and strip any trailing lines/spaces
$CurrentVersion = (Get-Content $LocalVersionFile).Trim()

# Convert GitHub Browser URL to Raw Link format
$RawURL = $GitHubWebURL -replace "github.com", "raw.githubusercontent.com" -replace "/blob/", "/"


# 2. Fetch CSV Data from GitHub safely
try {
    # Suppress progress bar UI glitch during background download
    $ProgressPreference = 'SilentlyContinue'
    $Response = Invoke-WebRequest -Uri $RawURL -UseBasicParsing -TimeoutSec 10
    
    if ($Response.StatusCode -eq 200) {
        $RawCSVData = $Response.Content
        
        # Parse the raw text straight into native PowerShell objects
        $CSVObjects = ConvertFrom-Csv -InputObject $RawCSVData
        
        $FormattedLog   = ""
        $FoundCurrent   = $false
        $NewUpdateCount = 0
        
        # 3. Loop through and sift the CSV records
        foreach ($Row in $CSVObjects) {
            
            # Extract all fields sequentially by ignoring header text properties
            $AllFields = $Row.psobject.Properties.Value | Where-Object { $_ -ne $null }
            
            # Position [0] is always the Version column
            $VerNumber = if ($AllFields[0]) { "$($AllFields[0])".Trim() } else { "" }
            
            # --- Sifting Logic ---
            # Case-insensitive comparison that targets your baseline version row
            if (-not $FoundCurrent) {
                if ($VerNumber.Equals($CurrentVersion, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $FoundCurrent = $true # Found where they are! Start logging everything downstream.
                }
                continue # Skip this row (it's either old or their active version)
            }
            
            # Every row processed past the match point is a brand new release
            $NewUpdateCount++
            
            # --- Positional Extraction (Bypasses Header Glitches) ---
            # Index 1 = 2nd Column (Changes)
            # Index 2 = 3rd Column (Purpose)
            # Index -1 = Absolute Last Column (New Features Flag)
            $Changes     = $AllFields[1]
            $Reason      = $AllFields[2]
            $RawFeatures = $AllFields[-1]
            
            # Clean and validate the feature flag
            $CheckFlag = if ($RawFeatures) { "$RawFeatures".Trim().ToUpper() } else { "" }
            if ($CheckFlag -eq "Y") {
                $NewFeatures = "Yes"
            } else {
                $NewFeatures = "No"
            }
            
            # Append this update segment to our main display string
            $FormattedLog += "--------------------------------------------------`n"
            $FormattedLog += "= NEW VERSION: $VerNumber`n"
            $FormattedLog += "   - Changes: $Changes`n"
            if (-not [string]::IsNullOrWhiteSpace($Reason)) {
                $FormattedLog += "   - Purpose: $Reason`n"
            }
            $FormattedLog += "   - New Features Included: $NewFeatures`n`n"
        }
        
        # 4. Final Display Logic
        # Only prompt the user if new releases were found downstream from their version
        if ($NewUpdateCount -gt 0) {
            # 64 = Blue Information Icon + OK button style
            $wshShell.Popup($FormattedLog, 0, "HotKey-CMD New Updates Found", 64) | Out-Null
        }
        # If $NewUpdateCount remains 0, it exits completely silently without disrupting workflows.
        
    } else {
        $wshShell.Popup("Could not download CSV file.`nServer Response Status: $($Response.StatusCode)", 0, "Download Error", 16) | Out-Null
    }
} catch {
    $wshShell.Popup("Failed to connect to GitHub to check for updates.", 0, "Connection Error", 16) | Out-Null
}