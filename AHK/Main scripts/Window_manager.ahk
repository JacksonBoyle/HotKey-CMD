; ============================================
; Window_Manager.ahk
; Updated to use context_engine.ahk
; ============================================
; created by - Jackson Boyle
;01/25/2026
;
;Revision - V0.0
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

; --------------------------------------------
; Globals
; --------------------------------------------
global DoubleAlt := false

; ============================================
; Double‑Alt detection
; ============================================
~Alt::
    DoubleAlt := (A_PriorHotkey = "~Alt" && A_TimeSincePriorHotkey < 400)
    KeyWait, Alt
return

; ============================================
; Window Manager Functions
; ============================================

WM_GetInitialPositions(ByRef mx, ByRef my, ByRef id, ByRef wx, ByRef wy, ByRef ww, ByRef wh) {
    MouseGetPos, mx, my, id
    if (!id)
        return false
    WinGetPos, wx, wy, ww, wh, ahk_id %id%
    return true
}

WM_MouseOffset(x1, y1, ByRef dx, ByRef dy) {
    MouseGetPos, cx, cy
    dx := cx - x1
    dy := cy - y1
}

WM_MoveWindowTo(id, nx, ny, ww, wh) {
    WinMove, ahk_id %id%, , %nx%, %ny%, %ww%, %wh%
}

WM_HasTitle(id) {
    WinGetTitle, t, ahk_id %id%
    return !!t
}

; --------------------------------------------
; Move window (Alt + LButton drag)
; --------------------------------------------
WM_Move() {
    static isMoving := false
    if (isMoving)
        return
    isMoving := true

    if (!WM_GetInitialPositions(mx, my, id, wx, wy, ww, wh)) {
        isMoving := false
        return
    }

    WinGet, st, MinMax, ahk_id %id%
    if (st) {
        PostMessage, 0x112, 0xf120,,, ahk_id %id%
        Sleep, 10
        MouseGetPos, mx, my
        WinGetPos, wx, wy, ww, wh, ahk_id %id%
        wx := mx - (ww / 2)
        wy := my - (wh / 2)
        WM_MoveWindowTo(id, wx, wy, ww, wh)
    }

    if (!WM_HasTitle(id)) {
        SoundBeep, 400, 40
        isMoving := false
        return
    }

    Loop {
        GetKeyState, btn, LButton, P
        if (btn = "U")
            break
        WM_MouseOffset(mx, my, dx, dy)
        nx := wx + dx
        ny := wy + dy
        WM_MoveWindowTo(id, nx, ny, ww, wh)
    }
    isMoving := false
}

; --------------------------------------------
; Resize window (Alt + RButton drag)
; --------------------------------------------
WM_Resize() {
    if (!WM_GetInitialPositions(mx, my, id, wx, wy, ww, wh))
        return

    WinGet, st, MinMax, ahk_id %id%
    if (st) {
        wx := 0, wy := 0, ww := A_ScreenWidth, wh := A_ScreenHeight
        WinRestore, ahk_id %id%
        Sleep, 10
        WinGetPos, wx, wy, ww, wh, ahk_id %id%
    }

    if (mx < wx + ww/2)
        winLeft := 1
    else
        winLeft := -1

    if (my < wy + wh/2)
        winUp := 1
    else
        winUp := -1

    Loop {
        GetKeyState, btn, RButton, P
        if (btn = "U")
            break

        MouseGetPos, cx, cy
        dx := cx - mx
        dy := cy - my

        if (winLeft == 1) {
            nW := ww - dx
            nX := wx + dx
        } else {
            nW := ww + dx
            nX := wx
        }

        if (winUp == 1) {
            nH := wh - dy
            nY := wy + dy
        } else {
            nH := wh + dy
            nY := wy
        }

        if (nW < 50)
            nW := 50
        if (nH < 50)
            nH := 50

        WinMove, ahk_id %id%, , %nX%, %nY%, %nW%, %nH%
    }
}

; --------------------------------------------
; Minimize window under cursor
; (Double‑Alt + LButton)
; --------------------------------------------
WM_Minimize_UnderCursor() {
    MouseGetPos,,, id
    if (!id)
        return
    WinMinimize, ahk_id %id%
}

; --------------------------------------------
; Maximize toggle (Double‑Alt + RButton)
; --------------------------------------------
WM_MaximizeToggle_UnderCursor() {
    MouseGetPos,,, id
    if (!id)
        return
    WinGet, st, MinMax, ahk_id %id%
    if (st)
        WinRestore, ahk_id %id%
    else
        WinMaximize, ahk_id %id%
}

; --------------------------------------------
; Close window (Double‑Alt + MButton)
; --------------------------------------------
WM_Close_UnderCursor() {
    MouseGetPos,,, id
    if (!id)
        return
    WinClose, ahk_id %id%
}


; ============================================
; Conditional Hotkeys using Context_Allows()
; ============================================

; --------------------------------------------
; Move window
; --------------------------------------------
#If (Context_Allows("window move"))
!LButton::WM_Move()
#If

; --------------------------------------------
; Resize window
; --------------------------------------------
#If (Context_Allows("window resize"))
!RButton::WM_Resize()
#If

; --------------------------------------------
; Minimize window
; --------------------------------------------
#If (DoubleAlt && Context_Allows("window minimize"))
~LButton::
    WM_Minimize_UnderCursor()
    DoubleAlt := false
return
#If

; --------------------------------------------
; Maximize window
; --------------------------------------------
#If (DoubleAlt && Context_Allows("window maximize"))
~RButton::
    WM_MaximizeToggle_UnderCursor()
    DoubleAlt := false
return
#If

; --------------------------------------------
; Close window
; --------------------------------------------
#If (DoubleAlt && Context_Allows("window close"))
~MButton::
    WM_Close_UnderCursor()
    DoubleAlt := false
return
#If