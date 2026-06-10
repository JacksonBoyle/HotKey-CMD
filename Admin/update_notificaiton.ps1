# ==============================================================================
# Script: update_notification.ps1 (PowerShell - Fixed Native Toast)
# Description: Sends update notifications directly to the Windows Action Center
#              with safe XML attribute character escaping.
# ==============================================================================

# --- GATEKEEPER CHECK ---
$CheckFilePath = Join-Path $PSScriptRoot "..\User Data\Update_notification_enable.txt"

if (Test-Path $CheckFilePath) {
    $FileContent = (Get-Content -Path $CheckFilePath -Raw).Trim().ToLower()
    if ($FileContent -ne "true") { exit }
} else { exit }
# -----------------------------

# 1. Dynamically target the preupdate script in the SAME folder
$TargetScriptName = "preupdate.ps1"
$TargetScriptPath = Join-Path $PSScriptRoot $TargetScriptName

# Clean and escape backslashes specifically for the XML parser string environment
$XmlSafeScriptPath = $TargetScriptPath -replace '\\', '\\'

# 2. Access the Native Windows Notification Engine via XML
[void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime]
[void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime]

# 3. Construct the Native XML Toast Layout with clean protocol routing
$ToastXml = @"
<toast activationType="protocol" launch="cmd.exe /c powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File '$XmlSafeScriptPath'">
    <visual>
        <binding template="ToastGeneric">
            <text>HotKey-CMD Update Available</text>
            <text>A new version has been detected. Click 'Update Now' or tap this card to begin the update process.</text>
        </binding>
    </visual>
    <actions>
        <action content="Update Now" 
                arguments="cmd.exe /c powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File '$XmlSafeScriptPath'" 
                activationType="protocol"/>
        <action content="Dismiss" 
                arguments="dismiss" 
                activationType="system"/>
    </actions>
</toast>
"@

# 4. Load the XML schema into the system runtime safely
$XmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
$XmlDoc.LoadXml($ToastXml)

# 5. Register the Application User Model ID (AppID)
$AppId = "Microsoft.Windows.PowerShell"

# 6. Fire the Notification cleanly into the system background layer
$Toast = New-Object Windows.UI.Notifications.ToastNotification $XmlDoc
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($Toast)
