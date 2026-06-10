; ============================================
; Hot_Key_menu.ahk
; ============================================
; Purpose: To give user a complete list of all active HotKeys
; and read the list from user_meassage.txt
;
; Created by - Jackson Boyle
; Modified: 05/13/2026
; ============================================

#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir %A_ScriptDir%

if not A_IsAdmin
    Run *RunAs "%A_ScriptFullPath%"

; --------------------------------------------
; Path Setup for Updates
; --------------------------------------------
updateFile := A_ScriptDir . "\..\..\Admin\update_available.txt"
updateText := ""
if FileExist(updateFile) {
    FileRead, statusRaw, %updateFile%
    statusRaw := Trim(statusRaw)
    if (statusRaw != "" && statusRaw != "no") {
        updateText := "Update Available: " . statusRaw
    }
}

; --------------------------------------------
; Read Saved Checkbox State (New Logic)
; --------------------------------------------
targetFolder := A_ScriptDir . "\..\..\User Data"
targetFile   := targetFolder . "\Update_notification_enable.txt"
initCheckboxState := ""

if FileExist(targetFile) {
    FileRead, savedState, %targetFile%
    savedState := Trim(savedState)
    if (savedState = "true") {
        initCheckboxState := "Checked" ; Sets the AHK option string to check it
    }
}

; --------------------------------------------
; Menu Tray Icon
; --------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\..\..\Images\HK_.ico

; --------------------------------------------
; Include shared context engine
; --------------------------------------------
#Include %A_ScriptDir%\..\Function Library\context_engine.ahk

filePath := A_ScriptDir . "\User_messages.txt"
MyLongMessage := ""
FileRead, MyLongMessage, %filePath%

; Create GUI
Gui, +AlwaysOnTop +Resize
Gui, Margin, 10, 10

; ============================================================
; UPDATE NOTIFICATION (STRICTLY TEXT ABOVE BUTTONS)
; ============================================================
if (updateText != "") {
    Gui, Font, s10 w600 ; Bold
    Gui, Add, Text, x10 y10 cRed, %updateText%
    buttonY := "y35" ; Move buttons down if text is present
} else {
    buttonY := "y10" ; Start buttons at top if no update
}

; ============================================================
; TOP BUTTON BAR & CHECKBOX
; ============================================================
Gui, Font, s9 w400 ; Reset font
Gui, Add, Button, x10 %buttonY% w150 h30 gAutoCorrect, AutoCorrect
Gui, Add, Button, x+10 yp w200 h30 gMappedDrives, Mapped Network Drive Update

; Gear icon button
gear := Chr(0x1F6E0)
Gui, Font, s20
Gui, Add, Button, x+10 yp w40 h30 gSettings, %gear%
Gui, Font

; Update icon button
update_sym := Chr(0x1F504)
Gui, Font, s20
Gui, Add, Button, x+10 yp w40 h30 gUpdate, %update_sym%
Gui, Font

; Checkbox placed to the right of the Update button (Dynamically Pre-populated)
Gui, Add, CheckBox, x+15 yp+5 vUpdateNotifyCB %initCheckboxState%, Update Notification

; ============================================================
; MAIN CONTENT AREA
; ============================================================
Gui, Add, Edit, x10 y+15 w600 r30 vMyEdit ReadOnly, %MyLongMessage%

Gui, Add, Edit, x10 y+10 w400 h25 vSearchText
Gui, Add, Button, x+10 yp w80 h25 gSearch, Search
Gui, Add, Button, x+10 yp w80 h25 gOK, OK

MyTitle := "HotKey command menu"
Gui, Show,, %MyTitle%
Return

; ============================================================
; LABELS
; ============================================================

Search:
GuiControlGet, SearchText,, SearchText
if (SubStr(SearchText, 1, 1) = ";")
    SearchText := SubStr(SearchText, 2)

GuiControlGet, MyEdit,, MyEdit
MatchingLines := ""
ScriptName := ""

Loop, Parse, MyEdit, `n, `r
{
    If InStr(A_LoopField, ".ahk")
        ScriptName := A_LoopField

    If InStr(A_LoopField, SearchText) && !InStr(A_LoopField, ".ahk")
    {
        MatchingLines .= A_LoopField . "`n"
        MatchingLines .= "Script Name: " . ScriptName . "`n`n"
    }
}

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
; 1. Submit GUI variables to gather whether the checkbox is 1 (true) or 0 (false)
Gui, Submit, NoHide

; 2. Ensure the folder directory exists before creating the text file
if !InStr(FileExist(targetFolder), "D") {
    FileCreateDir, %targetFolder%
}

; 3. Set string content based on check state and overwrite/create the target file
fileContent := (UpdateNotifyCB) ? "true" : "false"
FileDelete, %targetFile%
FileAppend, %fileContent%, %targetFile%

; 4. Clean up and close app
Gui, Destroy
ExitApp

GuiClose:
GuiEscape:
Gui, Destroy
ExitApp

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

Update:
 ; Recommend running your preupdate.ps1 here
 MsgBox, 64, Update, Checking for and applying updates...
Return
