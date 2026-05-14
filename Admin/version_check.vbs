' ==============================================================================
' Script: Run_VersionCheck_Silent.vbs
' Description: Dynamically locates and runs version_check.ps1 in the same folder.
' ==============================================================================
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

' 1. Get the folder path where THIS VBScript is located
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' 2. Build the path to the PowerShell script in the same folder
strPSPath = objFSO.BuildPath(strScriptPath, "version_check.ps1")

' 3. Execute PowerShell hidden (0) and wait for it to finish (True)
' Use -ExecutionPolicy Bypass to ensure it runs regardless of system restrictions
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File """ & strPSPath & """", 0, True