; ============================================
; Volume_up_down_with_scroll_wheel.ahk
;
; ============================================
; created by -
;01/26/2026
;
;Revision - V0.0

;base function -
;finds all the active hotkey if none active exits script
;volume up/down if hover over task bar
;uses whitelist/blacklist

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
; Performance tuning
; --------------------------------------------
SetWinDelay, -1
SetControlDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetKeyDelay, 0
CoordMode, Mouse
CoordMode, Pixel, Screen


; ============================================
; Volume_up_down_with_scroll_wheel Functions
; ============================================

MouseIsOver(class) {
    MouseGetPos,,, win
    WinGetClass, cls, ahk_id %win%
    return (cls = class)
}

; ============================================
; Conditional Hotkeys using Context_Allows()
; ============================================

; --------------------------------------------
; Volume up/down with scroll wheel
; --------------------------------------------
#If MouseIsOver("Shell_TrayWnd") &&  (Context_Allows("Taskbar Volume control"))
WheelUp::Send {Volume_Up} ; Volume up
WheelDown::Send {Volume_Down} ; Volume down
#If

; --------------------------------------------
; Mute with scroll wheel
; --------------------------------------------
#If MouseIsOver("Shell_TrayWnd") &&  (Context_Allows("Taskbar Mute"))
MButton::Send {Volume_Mute}
#If




