; ============================================
; Miscellaneous.ahk
;
; ============================================
; Purpose: colection of unique misclanous tool mainly windows bug fixes
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
;forces the calc button to work in all applications
#If Context_Allows("Force calculator button")
Launch_App2::  Safe_Run("C:\Windows\System32\calc.exe")
return
#If
;=============================================================================================================
#If Context_Allows("Shift + scroll for horizontal scroll")
+WheelDown::Send {WheelRight} ; Shift + scroll Wheel for horizontal scrolling right
+WheelUp::Send {WheelLeft} ; Shift + scroll Wheel for horizontal scrolling left
#If
;=============================================================================================================
#If Context_Allows("Set Capslock state to OFF upon start up")
SetCapsLockState , Off
#If
;=============================================================================================================
#If Context_Allows("Set Numlock to always ON")
SetNumLockState , AlwaysOn
#If
;=============================================================================================================
#If Context_Allows("Set Scrolllock to always OFF")
SetScrollLockState , AlwaysOff
#If
;=============================================================================================================









