; ============================================
; Folder_locations.ahk
;
; ============================================
; Purpose: list of folder location to open with shortcut HotKey
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


; --------------------------------------------
; Debug (optional)
; --------------------------------------------
;MsgBox % "Loaded hotstring keys:`n" . JoinKeys(Config)
;JoinKeys(obj) {
;   out := ""
;    for k, v in obj
;        if (k != "__version" && k != "__loaded_ok")
;            out .= k "`n"
;    return out
;}



; ============================================================
; Folder Loaction
; ============================================================

#If Context_Allows("Desktop shortcut")
#d::  Safe_Reopen("Desktop", A_Desktop)
return
#If

#If Context_Allows("Downloads shortcut")
#Down:: Safe_Reopen("Downloads", "shell:::{374DE290-123F-4565-9164-39C4925E467B}")
return
#If

#If Context_Allows("Recycle Bin shortcut")
#Up:: Safe_Reopen("Recycle Bin", "shell:RecycleBinFolder")
return
#If

#If Context_Allows("All task / God mode shortcut")
#,:: Safe_Reopen("All Tasks", "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}")
return
#If




