; ============================================
; Developer.ahk
;
; ============================================
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
#If Context_Allows("Reopen/Open Window spy")
^!PgUp::  Safe_Reopen("Window Spy", A_ScriptDir "\..\Window spy\WindowSpy.ahk")
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open HotKey command")
^+h:: Safe_Reopen("HotKey command", A_ScriptDir)
return
#If
;=============================================================================================================
#If Context_Allows("Reopen/Open AutoHotkey")
^!h:: Safe_Reopen(ahk_exe hh.exe, "C:\Program Files\AutoHotkey\AutoHotkey.chm")
return
#If
;=============================================================================================================
#If Context_Allows("Hot Key menu")
^!F12:: Safe_Reopen("HotKey command menu", A_ScriptDir "\..\Gui\Hot_Key_menu.ahk")
return
#If
;=============================================================================================================
#If Context_Allows("kill all Hot Keys")
^Esc:: Safe_Run(A_ScriptDir "\..\..\Admin\HK_kill.ps1")
return
#If
;=============================================================================================================
#If Context_Allows("Refresh Hot Keys ")
+Esc:: Safe_Run(A_ScriptDir "\..\Support scripts\HK_refresh.ps1")
return
#If
;=============================================================================================================











