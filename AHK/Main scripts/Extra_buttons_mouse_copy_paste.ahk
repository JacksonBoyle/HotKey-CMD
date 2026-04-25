; ============================================
; extra_buttons_mouse_Copy_Paste.ahk
;
; Created: 01/26/2026
; Revision: V0.0

;base function -
;remaps forward and back to copy and paste
;uses whitelist/blacklist

;
; Dependencies:
;   - context_engine.ahk
;   - config.csv
;   - Paste_fix_functions.ahk
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
#Include %A_ScriptDir%\..\Function Library\Paste_fix_functions.ahk
; --------------------------------------------
; Performance tuning
; --------------------------------------------
SetWinDelay, -1
SetControlDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetKeyDelay, 0
CoordMode, Mouse
CoordMode, Pixel, Screen


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


; ============================================
; Conditional Hotkeys using Context_Allows()
; ============================================

; --------------------------------------------
; XButton2 = Copy
; --------------------------------------------
#If (Context_Allows("Copy using mouse buttons"))
XButton2::Send ^c
#If

; --------------------------------------------
; XButton1 = Paste (with Explorer paste-fix)
; --------------------------------------------
#If (Context_Allows("Paste using mouse buttons"))
XButton1::
    ; If Explorer paste-fix is allowed, use the same function as Ctrl+V
    if (Context_Allows("Remove quotes from pasted file path"))
        PasteUnquotedThenQuoteClipboard()
    else
        Send ^v
return
#If