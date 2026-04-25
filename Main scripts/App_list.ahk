; ============================================
; App_list.ahk
;
; ============================================
; Purpose: list of app to open with shortcut HotKey
;
;
; created by - Jackson Boyle
;01/25/2026
;
;Revision - V0.0
;
; Dependencies:
;   - context_engine.ahk
;   - config.csv
; ============================================
#SingleInstance Force
#NoEnv
SetBatchLines, -1
SendMode, Input
SetWorkingDir %A_ScriptDir%

; --------------------------------------------
; Auto-elevate
; --------------------------------------------
if !A_IsAdmin {
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}
; --------------------------------------------
;menu tray icon
; --------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\..\..\Images\Tray_Icon.ico

; --------------------------------------------
; Include shared context engine
; --------------------------------------------
#Include %A_ScriptDir%\..\Function Library\context_engine.ahk


; --------------------------------------------
; Load CSV
; --------------------------------------------
csvPath := A_ScriptDir . "\..\..\Library\Main config\config.csv"
Config := Csv_Load(csvPath)


; --------------------------------------------
; checks the for all the hotkeys that used in current script used to exit script if none are active
; --------------------------------------------
required := GetRequiredContexts()
if !CheckRequiredContexts(required) {
    ;MsgBox, 48, Disabled, All context rules for this script are disabled.`nExiting.
    ExitApp
}


;=============================================================================================================
#If Context_Allows("Reopen/Open Windirstat")
^!x::  Safe_Reopen(ahk_exe windirstat.exe, "C:\Program Files (x86)\WinDirStat\windirstat.exe")
return
#If

#If Context_Allows("Open new Windirstat")
!+x::  Safe_Run("C:\Program Files (x86)\WinDirStat\windirstat.exe")
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open Word")
^!w::  Safe_Reopen(ahk_exe WINWORD.EXE, "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE")
return
#If

#If Context_Allows("Open new Word")
!+w::  Safe_Run("C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE")
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open OneNote")
^!n::  Safe_Reopen(ahk_exe ONENOTE.EXE, "C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE" )
return
#If

#If Context_Allows("Open new OneNote")
!+n::  Safe_Run("C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE" )
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open Outlook(new)")
^!o::  Safe_Reopen(ahk_exe olk.exe, "%C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE" )
return
#If

#If Context_Allows("Open new Outlook(new)")
!+o::  Safe_Run("C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE" )
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open Microsoft Teams")
^!t::  Safe_Reopen(ahk_exe Teams.exe, "shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams" )
return
#If

#If Context_Allows("Open new Microsoft Teams")
!+t::  Safe_Run("shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams" )
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open Notepad")
^!-::  Safe_Reopen(ahk_exe Notepad.exe, "C:\Windows\System32\notepad.exe" ) ; - next to =
return
#If

#If Context_Allows("Open new Notepad")
!+-::  Safe_Run("C:\Windows\System32\notepad.exe" ) ; - next to =
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open Notepad++")
^!=::  Safe_Reopen(ahk_exe notepad++.exe, "C:\Program Files (x86)\Notepad++\notepad++.exe" )
return
#If

#If Context_Allows("Open new Notepad++")
!+=::  Safe_Run("C:\Program Files (x86)\Notepad++\notepad++.exe")
return
#If
;=============================================================================================================

; Reopen or Open Snipping Tool (Ctrl+Alt+S)

#If Context_Allows("Reopen/Open snipping tool")
^!s::
    snipShellPath := "shell:AppsFolder\Microsoft.ScreenSketch_8wekyb3d8bbwe!App"

    ; Check for both possible modern process names
    if WinExist("ahk_exe SnippingTool.exe") || WinExist("ahk_exe ScreenSketch.exe")
    {
        WinActivate
        return
    }
    Safe_Run(snipShellPath)
return
#If


; Start a Fresh Snipping Session (Alt+Shift+S)

#If Context_Allows("Start a new snipping tool")
!+s::
    snipShellPath := "shell:AppsFolder\Microsoft.ScreenSketch_8wekyb3d8bbwe!App"

    ; If already open, kill it to ensure a clean "New Snip" state
    if WinExist("ahk_exe SnippingTool.exe")
        Process, Close, SnippingTool.exe
    else if WinExist("ahk_exe ScreenSketch.exe")
        Process, Close, ScreenSketch.exe

    Safe_Run(snipShellPath)

    ; Wait up to 2 seconds for the window to appear
    WinWait, ahk_class Microsoft-Windows-SnipperEditor,, 2


        Sleep 10
        Send !n ; Select "New"

return


#If WinActive("ahk_class Microsoft-Windows-SnipperEditor")
^c::
    Sleep 50
    Send ^{c}
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open Control Panel")
^!.:: Safe_Reopen("Control Panel", "shell:ControlPanelFolder")
return
#If
;=============================================================================================================








