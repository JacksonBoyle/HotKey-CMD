; ============================================
; smart_right_click_files_explorer.ahk
;
; ============================================
; created by -
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
    ;MsgBox, 48, Debug, % "Required Context: " . required . "`nResult: " . checkResult
    ExitApp
}



#If Context_Allows("Files explorer full right click menu")
;#IfWinActive, ahk_class CabinetWClass ; Only works in File Explorer
~RButton::
    ; Define the log file path
   ; logFilePath := "C:\AHK_RightClickLog.txt"
    ; Get the initial mouse position when the right button is pressed
    MouseGetPos, startX, startY
;    logMessage := "Right button pressed. Initial position: " startX ", " startY "`n"
 ;   FileAppend, %logMessage%, %logFilePath%
    send {LShift down}
    ; Wait for the right button to be released
    KeyWait, RButton, U
    ; Get the final mouse position after the right button is released
    MouseGetPos, endX, endY
 ;   logMessage := "Right button released. Final position: " endX ", " endY "`n"
 ;   FileAppend, %logMessage%, %logFilePath%
    Sleep 100
    ; Check if the mouse has moved (dragging action)
    if (abs(endX - startX) > 5 || abs(endY - startY) > 5)
    {
        ; Mouse was dragged, release Shift
        send {LShift up}
   ;     logMessage := "Drag detected. Shift key released.`n"
   ;     FileAppend, %logMessage%, %logFilePath%
    }
    else
    {
        ; Normal right-click action
        Sleep 50
        send {RButton up}
        Sleep 50
        send {LShift up}
     ;   logMessage := "No drag detected. Normal right-click action.`n"
      ;  FileAppend, %logMessage%, %logFilePath%
    }
    ; Add a separator for clarity
;    logMessage := "----------------------------------------`n"
 ;   FileAppend, %logMessage%, %logFilePath%
return
#If