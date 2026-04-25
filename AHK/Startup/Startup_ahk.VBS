' ============================================================
' SILENT ADMIN POWERSHELL LAUNCHER
' ============================================================
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShellApp = CreateObject("Shell.Application")

' 1. Get the folder where THIS VBScript is saved
strCurrentDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' 2. Define your PowerShell script name
strScriptName = "Startup_ahk.ps1"
strFinalPath = objFSO.BuildPath(strCurrentDir, strScriptName)

' 3. Execute with Admin Privileges ("runas")
If objFSO.FileExists(strFinalPath) Then
    ' Arguments: -NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\Script.ps1"
    strArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & strFinalPath & Chr(34)
    
    ' ShellExecute(File, Arguments, Directory, Operation, ShowWindow)
    ' "runas" triggers the Admin prompt
    ' 0 = Hidden Window
    objShellApp.ShellExecute "powershell.exe", strArgs, "", "runas", 0
Else
    MsgBox "Error: Could not find '" & strScriptName & "'", 16, "File Not Found"
End If