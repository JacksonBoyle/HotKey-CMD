; ============================================
; Hotstrings.ahk
;
; ============================================
; Purpose: give use easy common hotstings to use in daily use
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

; ============================================
; Hotstring Functions
; ============================================

; Slash date → /date
HS_SlashDate() {
    FormatTime, today,, MM/dd/yyyy
    SendInput %today%
}

; Underscore date → _date
HS_UnderscoreDate() {
    FormatTime, today,, yyyy_MM_dd
    SendInput %today%
}

; Lone i fix → i → I
HS_LoneIFix() {
    SendInput I
}

; ============================================
; Conditional Hotstrings using Context_Allows()
; ============================================

; --------------------------------------------
; Slash date
; --------------------------------------------
#If Context_Allows("Slash date MM/DD/YYYY")
:T*?:ddd::
    FormatTime, today,, MM/dd/yyyy
    SendInput, %today%
return
#If

; --------------------------------------------
; Underscore date
; --------------------------------------------
#If Context_Allows("Underscore date YYYY_MM_DD")
:T*?:zzz::
    FormatTime, today,, yyyy_MM_dd
    SendInput, %today%
return
#If

; --------------------------------------------
; Lone i fix
; --------------------------------------------
#If Context_Allows("lone i fix")
:T*?0:i ::
    Sleep, 30
    SendInput, I{Space}
return
#If