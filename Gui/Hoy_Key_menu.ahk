; ============================================
; Hot_Key_menu.ahk
;
; ============================================
; Purpose: To give user a complete list of all active HotKeys
;and read the list from user_meassage.txt
;
;created by - Jackson Boyle
;01/25/2026
;
;Revision - V0.0
; ============================================



#NoEnv
#SingleInstance, Force ; removes warning box from popping up when overwriting script
SendMode Input
SetWorkingDir %A_ScriptDir%
; --------------------------------------------
; Auto-elevate
; --------------------------------------------
if not A_IsAdmin
    Run *RunAs "%A_ScriptFullPath%" ; run as admin

; --------------------------------------------
;menu tray icon
; --------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\..\..\Images\HK_.ico ;tray icon

; --------------------------------------------
; Include shared context engine
; --------------------------------------------
#Include %A_ScriptDir%\..\Function Library\context_engine.ahk


; Define the path to the file
filePath := A_ScriptDir . "\User_messages.txt"


; Initialize the variable to hold the file content
MyLongMessage := ""



; Read the content of the file and store it in MyLongMessage
FileRead, MyLongMessage, %filePath%



; Create GUI with top button bar
Gui, +AlwaysOnTop +Resize
Gui, Margin, 10, 10

; ============================================================
; TOP BUTTON BAR
; ============================================================
Gui, Add, Button, x10  y10  w150 h30 gAutoCorrect, AutoCorrect
Gui, Add, Button, x+10 w200 h30 gMappedDrives, Mapped Network Drive Update

; Gear icon button (small square)
gear := Chr(0x1F6E0)
Gui, Font, s20  ; set font size to 20pt
Gui, Add, Button,  x+10 w40 h30 gSettings, %gear%
Gui, Font  ; reset to default

; ============================================================
; MAIN CONTENT AREA
; ============================================================
; Multi-line read-only text viewer
Gui, Add, Edit, x10 y+15 w600 r30 vMyEdit ReadOnly, %MyLongMessage%

; Search bar + button
Gui, Add, Edit, x10 y+10 w400 h25 vSearchText
Gui, Add, Button, x+10 w80 h25 gSearch, Search

; OK / Close button
Gui, Add, Button, x+10 w80 h25 gOK, OK
;
MyTitle := "HotKey command menu"
Gui, Show,, %MyTitle%
Return

Search:
GuiControlGet, SearchText,, SearchText

; Remove the first character if it's a semicolon
if (SubStr(SearchText, 1, 1) = ";")
{
    SearchText := SubStr(SearchText, 2)
}

GuiControlGet, MyEdit,, MyEdit
MatchingLines := ""
CurrentLine := 1
GreatestLine := 0
ScriptName := ""


; Split the content of the edit control into lines
Loop, Parse, MyEdit, `n, `r
{
    ; Check for .ahk and update GreatestLine and ScriptName if found
    If InStr(A_LoopField, ".ahk")
    {
        GreatestLine := CurrentLine
        ScriptName := A_LoopField
    }

    ; Check for the search text and skip lines containing .ahk
    If InStr(A_LoopField, SearchText) && !InStr(A_LoopField, ".ahk")
    {
        ; Append the result to the output message
        MatchingLines .= A_LoopField . "`n"
        MatchingLines .= "Script Name: " . ScriptName . "`n`n"
    }
    CurrentLine++
}



; Show the results in a custom GUI
Gui, SearchResults: New, +AlwaysOnTop
Gui, Add, Text, , The search term was found in the following lines:
Gui, Add, Edit, w600 r20 ReadOnly -E0x200 vResultEdit, %MatchingLines%
Gui, Add, Button, gCloseSearchResults, OK
Gui, Show,, Search Results
Return

CloseSearchResults:
Gui, SearchResults: Destroy
Return

OK:
Gui, Destroy
ExitApp
GuiClose:
Gui, Destroy
ExitApp
GuiEscape:
Gui, Destroy
ExitApp
Return



AutoCorrect:
MsgBox, Auto Correct button clicked.
Return

MappedDrives:
MsgBox, Mapped Network Drive Update clicked.
Return

Settings:
 Safe_Run(A_ScriptDir . "\Scriptsmith.ahk")
 ExitApp
Return
