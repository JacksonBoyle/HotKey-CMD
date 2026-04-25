; ======================================================================
; Message_Creator.ahk
; ----------------------------------------------------------------------
; Purpose:
;   Extracts message blocks from .ahk scripts and merges them with
;   selected CSV configuration data to generate User_messages.txt.
;
; Author:      Jackson Boyle
; Created:     01/25/2026
; Revision:    V0.0
;
; Dependencies:
;   - context_engine.ahk
;   - config.csv
; ======================================================================


; ======================================================================
;  ENVIRONMENT SETUP
; ======================================================================
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

; Performance tuning
SetWinDelay, -1
SetControlDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetKeyDelay, 0
CoordMode, Mouse
CoordMode, Pixel, Screen


; ======================================================================
;  INCLUDE SHARED LIBRARIES
; ======================================================================
#Include %A_ScriptDir%\..\Function Library\context_engine.ahk


; ======================================================================
;  CONFIGURATION
; ======================================================================
SearchDirectories := []
SearchDirectories.Push(A_ScriptDir . "\..\Personal scripts")

OutputFile := A_ScriptDir . "\..\GUI\User_messages.txt"
csvPath    := A_ScriptDir . "\..\..\Library\Main config\config.csv"


; ======================================================================
;  MAIN EXECUTION FLOW
; ======================================================================
AllMessages := ""

; Extract message blocks from script directories
ProcessDirectory(A_ScriptDir, AllMessages)
for index, directory in SearchDirectories
    ProcessDirectory(directory, AllMessages)

; Extract selected CSV data
ExtractCSV_Selected(csvPath, AllMessages)

; Write output file
FileDelete, %OutputFile%
FileAppend, %AllMessages%, %OutputFile%

if FileExist(OutputFile) {
    Sleep 100
    ExitApp
} else {
    MsgBox, Failed to create the file:`n%OutputFile%
}



; ======================================================================
;  FUNCTION LIBRARY
; ======================================================================

; ----------------------------------------------------------------------
; Extract message blocks between:
;   ;message_creater_start
;   ;message_creater_end
; ----------------------------------------------------------------------
ProcessDirectory(Directory, ByRef Messages) {
    Loop, Files, %Directory%\*.ahk
    {
        FileRead, FileContent, %A_LoopFileFullPath%
        MsgCollect := False

        Loop, Parse, FileContent, `n, `r
        {
            if (A_LoopField = ";message_creater_start") {
                MsgCollect := True
                continue
            }

            if (A_LoopField = ";message_creater_end") {
                MsgCollect := False
                continue
            }

            if MsgCollect
                Messages .= A_LoopField "`n"
        }
    }
}



; ----------------------------------------------------------------------
; Clean CSV cell:
;   - Trim whitespace
;   - Remove surrounding quotes
;   - Collapse doubled quotes
;   - Collapse multiple spaces
;   - Remove stray commas/spaces
; ----------------------------------------------------------------------
CleanCell(s) {
    s := Trim(s)

    if (SubStr(s,1,1) = """" && SubStr(s,0) = """")
        s := SubStr(s, 2, StrLen(s)-2)

    s := StrReplace(s, """""", """")

    while InStr(s, "  ")
        s := StrReplace(s, "  ", " ")

    s := RTrim(LTrim(s, " ,"), " ,")

    return s
}



; ----------------------------------------------------------------------
; Extract CSV:
;   - Column C
;   - Column D
;   - Column E
;   - Columns H → end (only if filled)
;   - Only when Column A is TRUE
; ----------------------------------------------------------------------
ExtractCSV_Selected(csvPath, ByRef Out) {
    if !FileExist(csvPath)
        return

    FileRead, text, %csvPath%
    if (ErrorLevel)
        return

    if (SubStr(text,1,3) = Chr(239) Chr(187) Chr(191))
        text := SubStr(text,4)

    Loop, Parse, text, `n, `r
    {
        line := Trim(A_LoopField)
        if (line = "")
            continue

        first := SubStr(line, 1, 1)
        if (first = ";" || first = "#")
            continue

        delim := InStr(line, A_Tab) ? A_Tab : ","
        fields := StrSplit(line, delim)

        if (fields.MaxIndex() < 5)
            continue

        state := ToLower(CleanCell(fields[1]))
        if !(state = "true" || state = "1" || state = "yes" || state = "on")
            continue

        colC := CleanCell(fields[3])
        colD := CleanCell(fields[4])
        colE := CleanCell(fields[5])

        extras := ""
        if (fields.MaxIndex() >= 8) {
            Loop % fields.MaxIndex() {
                if (A_Index < 8)
                    continue

                cell := CleanCell(fields[A_Index])
                if (cell != "")
                    extras .= cell " | "
            }
            extras := RTrim(extras, " | ")
        }

        Out .= colC " | " colD " | " colE
        if (extras != "")
            Out .= " | " extras

        Out .= "`n`n"
    }
}