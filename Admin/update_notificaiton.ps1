# ==============================================================================
# Script: update_notification.ps1 (PowerShell)
# Description: High-DPI scaled safe notification UI that forces buttons to remain
#              visible using absolute container anchoring.
# ==============================================================================

# 1. Dynamically target the script in the SAME folder
$TargetScriptName = "preupdate.ps1"
$TargetScriptPath = Join-Path $PSScriptRoot $TargetScriptName
# Clean backslashes for the HTML environment
$SafePath = $TargetScriptPath -replace '\\', '\\'

# 2. Dynamically target the local .ico file using relative paths
$RelativeIconPath = Join-Path $PSScriptRoot "..\Images\Tray_Icon.ico"
$AbsoluteIconPath = [System.IO.Path]::GetFullPath($RelativeIconPath)
$SafeIconPath     = $AbsoluteIconPath -replace '\\', '\\'

# 3. Define the HTML and structural layout of the notification box
$HtaContent = @"
<html>
<head>
<title>HotKey-CMD Update</title>
<hta:application 
    id="oNotification"
    applicationname="HotKeyUpdate"
    border="none"
    caption="no"
    showintaskbar="no"
    singleinstance="yes"
    sysmenu="no"
    windowstate="normal"
    icon="$SafeIconPath"
/>
<style>
    body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #1f1f1f;
        color: #ffffff;
        margin: 0;
        padding: 15px;
        overflow: hidden;
        border: 1px solid #3c3c3c;
    }
    .notification-container {
        display: table;
        width: 100%;
    }
    .icon-column {
        display: table-cell;
        vertical-align: top;
        width: 50px;
        padding-right: 12px;
    }
    .icon-img {
        width: 45px;
        height: 45px;
    }
    .text-column {
        display: table-cell;
        vertical-align: top;
    }
    .title {
        font-size: 14px;
        font-weight: bold;
        color: #00a2ed;
        margin-bottom: 4px;
    }
    .body-text {
        font-size: 12px;
        color: #cccccc;
        line-height: 1.4;
    }
    /* Force buttons to anchor perfectly near the bottom of the window */
    .btn-container {
        position: absolute;
        bottom: 15px;
        right: 15px;
    }
    .btn {
        color: white;
        border: none;
        padding: 6px 15px;
        font-size: 12px;
        cursor: pointer;
        border-radius: 2px;
        margin-left: 8px;
    }
    .btn-update {
        background-color: #0078d4;
    }
    .btn-update:hover {
        background-color: #106ebe;
    }
    .btn-close {
        background-color: #333333;
        border: 1px solid #555555;
    }
    .btn-close:hover {
        background-color: #444444;
        border-color: #777777;
    }
</style>

<script language="VBScript">
    Sub Window_OnLoad
        ' Position the window at the bottom right corner of the screen
        Dim width, height, x, y
        width = 400 ' Expanded width
        height = 180 ' Expanded height to comfortably accommodate Windows Display Scaling
        x = window.screen.width - width - 25
        y = window.screen.height - height - 65
        window.resizeTo width, height
        window.moveTo x, y
    End Sub

    Sub RunUpdate
        Set objShell = CreateObject("WScript.Shell")
        Dim cmd
        cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & "$SafePath" & """"
        objShell.Run cmd, 0, False
        window.close
    End Sub

    Sub CloseWindow
        window.close
    End Sub
</script>
</head>
<body>
    <div class="notification-container">
        <div class="icon-column">
            <img class="icon-img" src="$SafeIconPath">
        </div>
        
        <div class="text-column">
            <div class="title">HotKey-CMD Update Available</div>
            <div class="body-text">A new version has been detected. Click below to begin the update process.</div>
        </div>
    </div>
    
    <div class="btn-container">
        <button class="btn btn-close" onclick="CloseWindow">Close</button>
        <button class="btn btn-update" onclick="RunUpdate">Update Now</button>
    </div>
</body>
</html>
"@

# 4. Write out the temporary execution frame
$HtaPath = Join-Path $env:TEMP "hk_update_toast.hta"
Set-Content -Path $HtaPath -Value $HtaContent

# 5. Launch the interface window seamlessly
Start-Process -FilePath "mshta.exe" -ArgumentList "`"$HtaPath`""