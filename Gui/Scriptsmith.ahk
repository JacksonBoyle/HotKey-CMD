; ============================================
; Scriptsmith.ahk
;
; ============================================
; Purpose: to read csv file and and give use a way to turn off
; and on HotKey.
;
;
;created by - Jackson Boyle
;01/25/2026
;
;Revision - V0.0
; ============================================




; ==========================================
; Scriptsmith GUI — Globals & Configuration
; ==========================================
; These globals define layout, behavior, and data structures used
; throughout the script. They must appear before any function that
; references them.

#NoEnv
#SingleInstance, Force
SetBatchLines, -1
ListLines, Off
SetTitleMatchMode, 2
; --------------------------------------------
; Auto-elevate
; --------------------------------------------
if not A_IsAdmin
    Run *RunAs "%A_ScriptFullPath%" ; run as admin

; --------------------------------------------
;menu tray icon
; --------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\..\..\Images\Tray_Icon.ico


; ---------- App Name & CSV Path ----------
global APP_NAME := "Scriptsmith"
global CSV_PATH := A_ScriptDir "\..\..\Library\Main config\config.csv"

; ---------- Layout Constants ----------
global MARGIN_X := 12, MARGIN_Y := 12
global TOP_BTN_H := 28
global TOP_BTN_W := 140
global TOP_BTN_GAP := 10
global ROW_H := 26, GAP_X := 18
global INFO_W := 26, INFO_H := 22
global CHK_W := 18, CHK_H := 18

; ---------- Colors ----------
global COLOR_INFO := "Blue"

; ---------- Data Structures ----------
global Items := []          ; All item objects
global ItemMap := {}        ; key → item
global Lines := []          ; Raw CSV lines

; ---------- Category Grouping ----------
global Groups := {}         ; category → array of items
global CatOrder := []       ; category display order
global CAT_UNCATEGORIZED := "Other"

global GROUP_PAD_TOP := 20
global GROUP_PAD_BOTTOM := 10
global GROUP_GAP_Y := 14

; ---------- Mode (3‑state dropdown) ----------
global MODE_W := 180
global MODE_LIST := ["Always active"
                   , "Active for all windows excluding"
                   , "Active only for specific windows"]
global MODE_DEFAULT := 1
global CSV_MODE_COL := 5

; ---------- Per‑row App List ----------
global CSV_APPS_START_COL := 8
global WB_BTN_W := 36, WB_BTN_H := 21

; ---------- Scrolling ----------
global ScrollCtrls := []     ; controls that move
global ScrollY := 0          ; current scroll offset
global ScrollStep := 30      ; pixels per scroll step



; ==========================================
; String Helpers
; ==========================================
; Utility functions used throughout CSV parsing and GUI logic.

Str_ToBool(val) {
    v := Str_Lower(Str_Trim(val))
    return (v = "true" || v = "1" || v = "yes" || v = "y" || v = "on")
}

Str_TrimQuotes(s) {
    s := Str_Trim(s)
    if (StrLen(s) >= 2 && SubStr(s,1,1) = """" && SubStr(s,0) = """")
        s := SubStr(s, 2, StrLen(s)-2)
    return s
}

Str_Trim(s) {
    s := RegExReplace(s, "^\s+")
    s := RegExReplace(s, "\s+$")
    return s
}

Str_Lower(s) {
    t := s
    StringLower, t, t
    return t
}



; ==========================================
; Mode Helpers
; ==========================================
; Converts CSV mode text/number into internal mode index.

Mode_Parse(val) {
    global MODE_DEFAULT
    s := Str_Lower(Str_Trim(val))

    if (s = "")
        return MODE_DEFAULT

    if s is integer
    {
        n := s + 0
        return (n >= 1 && n <= 3) ? n : MODE_DEFAULT
    }

    if (InStr(s, "always"))
        return 1
    if (InStr(s, "exclud"))
        return 2
    if (InStr(s, "only") || InStr(s, "specific"))
        return 3

    return MODE_DEFAULT
}

Mode_Text(idx) {
    global MODE_LIST
    return (idx >= 1 && idx <= MODE_LIST.MaxIndex()) ? MODE_LIST[idx] : MODE_LIST[1]
}



; ==========================================
; CSV Field Utilities
; ==========================================
; These functions handle CSV parsing, field extraction, and
; field replacement. They support quoted fields and embedded commas.

CSV_Split(line) {
    arr := []
    i := 1, len := StrLen(line)
    field := "", inQuotes := false

    while (i <= len) {
        ch := SubStr(line, i, 1)

        if (inQuotes) {
            if (ch = """") {
                next := SubStr(line, i+1, 1)
                if (next = """") {
                    field .= """"
                    i += 2
                } else {
                    inQuotes := false
                    i++
                }
            } else {
                field .= ch
                i++
            }
        } else {
            if (ch = """") {
                inQuotes := true
                i++
            } else if (ch = ",") {
                arr.Push(field)
                field := ""
                i++
            } else {
                field .= ch
                i++
            }
        }
    }

    arr.Push(field)

    for k, v in arr
        arr[k] := Str_Trim(v)

    return arr
}

CSV_FieldRanges(line) {
    ranges := []
    len := StrLen(line)
    i := 1, start := 1, inQuotes := false

    while (i <= len) {
        ch := SubStr(line, i, 1)

        if (inQuotes) {
            if (ch = """") {
                next := SubStr(line, i+1, 1)
                if (next = """") {
                    i += 2
                } else {
                    inQuotes := false
                    i++
                }
            } else {
                i++
            }
        } else {
            if (ch = """") {
                inQuotes := true
                i++
            } else if (ch = ",") {
                ranges.Push({start:start, end:i-1})
                i++
                start := i
            } else {
                i++
            }
        }
    }

    ranges.Push({start:start, end:len})
    return ranges
}

CSV_ReplaceField(line, fieldIndex, newVal) {
    if !(fieldIndex is integer)
        return line
    if (fieldIndex < 1)
        return line

    ranges := CSV_FieldRanges(line)
    count := (IsObject(ranges) ? ranges.MaxIndex() : 0)

    if (fieldIndex <= count) {
        r := ranges[fieldIndex]
        before := (r.start > 1) ? SubStr(line, 1, r.start - 1) : ""
        after := SubStr(line, r.end + 1)
        return before . newVal . after
    }

    needed := fieldIndex - count
    if (needed > 1) {
        missing := needed - 1
        Loop, %missing%
            line .= ","
    }

    if (count)
        line .= ","

    line .= newVal
    return line
}

CSV_SetTailFrom(line, startIndex, arr) {
    ranges := CSV_FieldRanges(line)
    count := (IsObject(ranges) ? ranges.MaxIndex() : 0)

    prefix := ""
    if (startIndex > 1) {
        if (count >= startIndex - 1) {
            r := ranges[startIndex - 1]
            prefix := SubStr(line, 1, r.end)
        } else {
            prefix := line
            missing := (startIndex - 1) - count
            Loop, %missing%
                prefix .= ","
        }
    }

    out := prefix
    if (startIndex > 1)
        out .= ","

    if (IsObject(arr) && arr.MaxIndex()) {
        first := true
        for _, v in arr {
            if (!first)
                out .= ","
            out .= v
            first := false
        }
    }

    return out
}



; ==========================================
; LoadFromCSV — Build Data Model
; ==========================================
; Converts CSV rows into item objects and organizes them into
; categories for GUI construction.

LoadFromCSV(path) {
    global Items, ItemMap, Lines
    global Groups, CatOrder, CAT_UNCATEGORIZED, CSV_APPS_START_COL

    Items := []
    ItemMap := {}
    Lines := []

    if !FileExist(path)
        return false

    FileRead, raw, %path%
    if (ErrorLevel)
        return false

    raw := RegExReplace(raw, "\r\n|\r", "`n")

    Loop, Parse, raw, `n
        Lines.Push(A_LoopField)

    Groups := {}
    CatOrder := []

    Loop, Parse, raw, `n
    {
        line := Str_Trim(A_LoopField)
        ln := A_Index

        if (A_Index = 1)
            continue
        if (line = "" || SubStr(line,1,1) = ";")
            continue

        fields := CSV_Split(line)
        if (fields.MaxIndex() < 2)
            continue

        colA := fields[1] != "" ? fields[1] : "false"
        colB := fields[2] != "" ? fields[2] : "Item " A_Index
        colC := fields.MaxIndex() >= 3 ? fields[3] : ""
        colD := fields.MaxIndex() >= 4 ? fields[4] : ""
        colE := fields.MaxIndex() >= 5 ? fields[5] : ""

        apps := []
        maxi := fields.MaxIndex()
        if (maxi >= CSV_APPS_START_COL) {
            idx := CSV_APPS_START_COL
            while (idx <= maxi) {
                v := Str_Trim(Str_TrimQuotes(fields[idx]))
                if (v != "")
                    apps.Push(v)
                idx++
            }
        }

        colB := Str_Trim(Str_TrimQuotes(colB))
        colC := Str_Trim(Str_TrimQuotes(colC))
        colD := Str_Trim(Str_TrimQuotes(colD))
        colE := Str_Trim(Str_TrimQuotes(colE))

        if (colD = "")
            colD := CAT_UNCATEGORIZED

        state := Str_ToBool(colA) ? 1 : 0
        mode := Mode_Parse(colE)

        key := RegExReplace(colB, "[^A-Za-z0-9]+")
        if (key = "")
            key := "Item" A_TickCount
        while (ItemMap.HasKey(key))
            key := key "_x" A_TickCount A_Index

        it := { key:key
              , label:colB
              , title:colB
              , text:colC
              , state:state
              , mode:mode
              , lineIdx:ln
              , cat:colD
              , apps:apps }

        Items.Push(it)
        ItemMap[key] := it

        if !Groups.HasKey(colD) {
            Groups[colD] := []
            CatOrder.Push(colD)
        }
        Groups[colD].Push(it)
    }
    return true
}

GetItem(key) {
    global ItemMap
    return ItemMap.HasKey(key) ? ItemMap[key] : ""
}

ReloadFromCSV:
{
    ; Reload the CSV file into memory
    if (!LoadFromCSV(CSV_PATH)) {
        MsgBox, 16, %APP_NAME% - Error, Failed to reload CSV file.
        Return
    }

    ; Rebuild the GUI from the new data
    Gosub, DrawRows

    ; Apply checkbox + mode states
    Gosub, ApplyStatesToControls
}
return

LoadRecommended:
{
    ; Path to recommended config
    recPath := A_ScriptDir "\..\..\Library\Main config\recommended_config.csv"

    if !FileExist(recPath) {
        MsgBox, 16, %APP_NAME% - Error, recommended_config.csv not found.`n`n%recPath%
        Return
    }

    ; Load recommended CSV instead of normal config
    if (!LoadFromCSV(recPath)) {
        MsgBox, 16, %APP_NAME% - Error, Failed to load recommended_config.csv.
        Return
    }

    ; Rebuild GUI with recommended settings
    Gosub, DrawRows
    Gosub, ApplyStatesToControls
}
Return


; ==========================================
; GUI Construction
; ==========================================
; Builds the main window dynamically based on Items[] and Groups[].

Gui_EscapeAmps(s) {
    t := s
    StringReplace, t, t, &, &&, All
    return t
}




; ==========================================
; Scriptsmith GUI with Tabs, Headers, and Adjusted Spacing
; ==========================================

DrawRows:
{
    Gui, 1:Destroy
    Gui, 1:Default
    Gui, +Resize +MinSize900x600
    Gui, Margin, %MARGIN_X%, %MARGIN_Y%

    ; ---------- Top buttons ----------
    Gui, Add, Button, vBtnReload gReloadFromCSV w140 h28, Revert Changes
    Gui, Add, Button, vBtnRecommended gLoadRecommended x+10 w140 h28, Recommended
    Gui, Add, Button, vBtnHelp gShowHelp x+10 w140 h28, Help
    Gui, Add, Button, vBtnSaveClose gSaveAndClose x+10 w140 h28, Save && Close
    Gui, Add, Button, vBtnClose gExitAppNow x+10 w100 h28, Close

    ; ---------- Tabs ----------
    tabList := ""
    for idx, catName in CatOrder
        tabList .= (tabList = "" ? "" : "|") catName

    tabX := MARGIN_X
    tabY := TOP_BTN_H + 20
    tabW := 870
    tabH := 520

    Gui, Add, Tab, x%tabX% y%tabY% w%tabW% h%tabH% vMainTab, %tabList%

    ; ---------- Define column positions inside each tab ----------
    ctrlX_Info  := 12
    ctrlX_Check := 60    ; moved checkbox slightly right
    ctrlX_Mode  := 125   ; moved dropdown slightly left
    ctrlX_WB    := 325
    ctrlX_Label := 450

    ; ---------- Build items for each category ----------
    for idxCat, catName in CatOrder {
        Gui, Tab, %catName%

        ; --- Header Row ---
        headerY := 75  ; fixed top of tab for column titles
        Gui, Font, Bold
        Gui, Add, Text, x%ctrlX_Info% y%headerY% w26 Center, More Info
        Gui, Add, Text, x%ctrlX_Check% y%headerY% w40 Center, Enable
        Gui, Add, Text, x%ctrlX_Mode% y%headerY% w180 Center, Filter
        Gui, Add, Text, x%ctrlX_WB% y%headerY% w36 Center, Whitelist/Blacklist
        Gui, Add, Text, x%ctrlX_Label% y%headerY% w300, Name
        Gui, Font, Norm

        ; --- Horizontal line under header ---
        lineY := headerY + ROW_H - 2
        Gui, Add, Text, x0 y%lineY% w%tabW% h2 BackgroundBlack

        ; start Y position for first row in tab (below header)
        yOffset := headerY + ROW_H + 2

        itemsInCat := Groups[catName]
        if !(IsObject(itemsInCat) && itemsInCat.MaxIndex())
            continue

        for _, it in itemsInCat {
            ; --- Info Button ---
            ctrlName := "Info_" it.key
            Gui, Add, Button, x%ctrlX_Info% y%yOffset% w26 h22 v%ctrlName% gInfoBtn, ?

            ; --- Checkbox ---
            ctrlName := it.key
            Gui, Add, CheckBox, x%ctrlX_Check% y%yOffset% w40 h22 v%ctrlName% gOnToggle,

            ; --- Mode Dropdown ---
            ctrlName := "Mode_" it.key
            Gui, Add, DropDownList, x%ctrlX_Mode% y%yOffset% w180 h60 v%ctrlName% gOnModeChange AltSubmit, % MODE_LIST[1] "|" MODE_LIST[2] "|" MODE_LIST[3]

            ; --- W/B Button ---
            ctrlName := "WB_" it.key
            Gui, Add, Button, x%ctrlX_WB% y%yOffset% w36 h22 v%ctrlName% gOnWBEdit, W/B

            ; --- Label (clickable) ---
            ctrlName := "Lbl_" it.key
            Gui, Add, Text, x%ctrlX_Label% y%yOffset% w300 h22 v%ctrlName% gLblClick, % it.label

            ; move down for next row
            yOffset += ROW_H
        }
    }

    Gui, Tab  ; end tab control
    Gui, Show, , %APP_NAME%
    Gosub, ApplyStatesToControls
}
Return

; ==========================================
; Apply saved states to checkboxes and dropdowns
; ==========================================
ApplyStatesToControls:
{
    for idx, it in Items {
        GuiControl,, % it.key, % it.state
        GuiControl, Choose, % "Mode_" it.key, % it.mode
    }
}
Return



; ==========================================
; Info button, label click, toggle, mode, W/B remain unchanged
; ==========================================
OnToggle:
{
    ctrl := A_GuiControl
    GuiControlGet, cur,, %ctrl%
    it := GetItem(ctrl)
    if (it) {
        it.state := cur ? 1 : 0
        Handle_Action(it.key, it.state)
    }
}
Return

LblClick:
{
    lbl := A_GuiControl
    key := (SubStr(lbl,1,4) = "Lbl_") ? SubStr(lbl,5) : lbl
    GuiControlGet, cur,, %key%
    newState := !cur
    GuiControl,, %key%, % newState
    it := GetItem(key)
    if (it) {
        it.state := newState ? 1 : 0
        Handle_Action(it.key, it.state)
    }
}
Return

InfoBtn:
{
    ctrl := A_GuiControl
    key := (SubStr(ctrl,1,5) = "Info_") ? SubStr(ctrl,6) : ctrl
    item := GetItem(key)
    if (!item)
        item := {title:"Info", text:"No description available for: " key}

    if (!InfoGuiBuilt) {
        Gui, 2:New, +AlwaysOnTop +Owner1 +ToolWindow, Details
        Gui, 2:Margin, 12, 12
        Gui, 2:Add, Text, vInfoTitle w420 +0x200 cBlue, Title
        Gui, 2:Add, Text, vInfoText w420, Body
        Gui, 2:Add, Button, gInfoClose w90 Default, Close
        InfoGuiBuilt := true
    }

    Gui, 2:Default
    GuiControl,, InfoTitle, % item.title
    GuiControl,, InfoText, % item.text

    MouseGetPos, mx, my
    Gui, 2:Show, x%mx% y%my% AutoSize, % "Details - " item.title
    Gui, 1:Default
}
Return

InfoClose:
Gui, 2:Hide
Return

OnModeChange:
{
    ctrl := A_GuiControl
    key := (SubStr(ctrl,1,5) = "Mode_") ? SubStr(ctrl,6) : ctrl
    GuiControlGet, pos,, %ctrl%
    it := GetItem(key)
    if (it)
        it.mode := (pos >= 1 && pos <= 3) ? pos : MODE_DEFAULT
}
Return

; ==========================================
; Save / Reload / Recommended / W/B / Exit remain unchanged
; ==========================================




; ===============================
; Scrollbar Movement
; ===============================
OnScroll:
{
    Gui, Submit, NoHide
    global ScrollCtrls

    ; Calculate total height of content
    totalHeight := 0
    for _, ctrl in ScrollCtrls
        if (ctrl.y > totalHeight)
            totalHeight := ctrl.y

    ; Get scrollbar position (0-100)
    GuiControlGet, pos, , VScrollBar
    scrollOffset := - (pos / 100.0) * totalHeight

    ; Move each control
    for _, ctrl in ScrollCtrls {
        ctrlName := ctrl.name
        newY := ctrl.y + scrollOffset
        GuiControl, Move, %ctrlName%, y%newY%
    }
}
Return


; ===============================
; Mouse Wheel
; ===============================
OnMouseWheel(wParam, lParam) {
    GuiControlGet, pos,, VScrollBar
    delta := NumGet(wParam, 0, "Int") >> 16
    pos -= delta * 3  ; wheel speed
    if pos < 0
        pos := 0
    if pos > 100
        pos := 100
    GuiControl,, VScrollBar, %pos%
    Gosub, OnScroll
}







; ==========================================
; Event Handlers
; ==========================================
; These respond to user interaction with the GUI:
;   - Checkbox toggles
;   - Label clicks (toggle behavior)
;   - Info button popups
;   - Mode dropdown changes
;   - Tooltip display on hover






InfoWinEscape:
InfoWinClose:
    Gui, 2:Hide
Return

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    static lastCtrl := ""
    CoordMode, Mouse, Window
    MouseGetPos, , , , ctrl, 2

    if (ctrl != lastCtrl) {
        lastCtrl := ctrl
        Tooltip

        if (SubStr(ctrl,1,4) = "Lbl_")
            key := SubStr(ctrl,5)
        else if (SubStr(ctrl,1,5) = "Info_")
            key := SubStr(ctrl,6)
        else
            return

        it := GetItem(key)
        if (it && it.text) {
            Tooltip, % it.text
            SetTimer, __HideTip, -2500
        }
    }
    return
}

__HideTip:
    Tooltip
Return

; ==========================================
; Help Window
; ==========================================

ShowHelp:
{
    if (!HelpGuiBuilt) {
        Gui, 4:New, +AlwaysOnTop +Owner1 +ToolWindow, Help
        Gui, 4:Margin, 12, 12

        ; Set font size for help text
        Gui, 4:Font, s11


        helpText =
        (
This tool allows you to enable, disable, and configure features
defined in your config.csv file.

COLUMN GUIDE
-- More Info - Click the ? button to view details about the item.
-- Enable - Toggles the hotkey on or off.
-- Filter - Select how the feature behaves (Normal / Whitelist / Blacklist).
-- W/B - Opens a list of applications for whitelist/blacklist mode.
-- Name - Clicking the name toggles its checkbox.

BUTTONS
-- Revert Changes - Reloads from config.csv.
-- Recommended - Loads recommended_config.csv (but does NOT save to it).
-- Save & Close - Saves your changes to config.csv.
-- Close - Exits without saving.

OTHER NOTES
-- Clicking the name toggles its checkbox as well as the check box.
-- All changes are stored only when you click Save & Close.
-- Recommended mode is hotkey comand recomended settings.
        )

        Gui, 4:Add, Edit, w600 r25 ReadOnly -Wrap vHelpText, %helpText%
        Gui, 4:Add, Button, w100 gHelpClose, Close

        HelpGuiBuilt := true
    }

    MouseGetPos, mx, my
    Gui, 4:Show, x%mx% y%my% AutoSize, Help
}
Return

HelpClose:
4GuiEscape:
4GuiClose:
    Gui, 4:Hide
Return



Handle_Action(key, state) {
    return
}



; ==========================================
; Save Logic
; ==========================================
; Writes the current GUI state back into the CSV file.

SaveAndClose:
{
    Gui, +OwnDialogs
    GuiControl, Disable, BtnSaveClose

    if (!EnsureCsvClosed(CSV_PATH, APP_NAME " - Save")) {
        GuiControl, Enable, BtnSaveClose
        return
    }

    if (SaveSelectionsToCsv(CSV_PATH)) {
        MsgBox, 64, %APP_NAME%, Changes have been saved successfully.
        ExitApp
    } else {
        MsgBox, 16, %APP_NAME% - Save Failed, Changes could not be saved.
        GuiControl, Enable, BtnSaveClose
    }
}
Return

SaveSelectionsToCsv(path) {
    global Items, Lines, CSV_MODE_COL, CSV_APPS_START_COL, APP_NAME

    if (!IsObject(Lines) || (Lines.MaxIndex() = "")) {
        MsgBox, 16, %APP_NAME% - Save Failed, CSV not loaded in memory.
        return 0
    }

    for _, it in Items {
        idx := it.lineIdx
        if !(idx >= 1 && idx <= Lines.MaxIndex())
            continue

        GuiControlGet, cur,, % it.key
        newA := cur ? "true" : "false"

        GuiControlGet, mpos,, % "Mode_" it.key
        modeIdx := (mpos >= 1 && mpos <= 3) ? mpos : it.mode
        modeText := Mode_Text(modeIdx)

        line := Lines[idx]
        if (line = "")
            continue

        line := CSV_ReplaceField(line, 1, newA)
        line := CSV_ReplaceField(line, CSV_MODE_COL, modeText)

        apps := []
        if (IsObject(it.apps)) {
            for _, v in it.apps {
                v := Str_Trim(v)
                if (v != "")
                    apps.Push(v)
            }
        }

        line := CSV_SetTailFrom(line, CSV_APPS_START_COL, apps)
        Lines[idx] := line
    }

    tmp := path ".tmp"
    FileDelete, %tmp%

    for i, line in Lines
        FileAppend, % line "`r`n", %tmp%

    FileMove, %tmp%, %path%, 1
    if (ErrorLevel) {
        MsgBox, 16, %APP_NAME% - Save Failed, Could not replace CSV file.`nErrorLevel=%ErrorLevel%
        return 0
    }
    return 1
}



; ==========================================
; W/B Editor
; ==========================================
; Popup editor for whitelist/blacklist application lists.

OnWBEdit:
{
    ctrl := A_GuiControl
    key := (SubStr(ctrl,1,3) = "WB_") ? SubStr(ctrl,4) : ctrl
    it := GetItem(key)
    if (!it)
        return

    txt := ""
    if (IsObject(it.apps)) {
        for _, app in it.apps
            txt .= app "`r`n"
        if (SubStr(txt,0) = "`n")
            txt := SubStr(txt, 1, StrLen(txt)-2)
    }

   if (!WBGuiBuilt)
   {
    Gui, 3:New, +Owner1 +AlwaysOnTop +ToolWindow, Application List
    Gui, 3:Margin, 10, 10
    Gui, 3:Add, Text, vWB_Title w450 +0x200, Applications (one per line):
    Gui, 3:Add, Edit, vWB_Edit gWB_EditClick w400 r12

    ; Buttons
    Gui, 3:Add, Button, gWB_Save w90 Default, Save
    Gui, 3:Add, Button, gWB_Cancel x+10 w90, Cancel
    Gui, 3:Add, Button, gWB_Spy x+10 w110, Window Spy

    WBGuiBuilt := true
    WB_CurrentKey := ""
    }

    WB_CurrentKey := key

    Gui, 3:Default
    GuiControl,, WB_Title, % "Applications for: " it.title " Please use Window Spy to identify .exe if needed"
    GuiControl,, WB_Edit, % txt

    MouseGetPos, mx, my
    Gui, 3:Show, x%mx% y%my% AutoSize
        , % "Apps - " it.title "  (example: chrome.exe, explorer.exe)"

    Gui, 1:Default
}
Return


WB_EditClick:
{
    GuiControlGet, cur,, WB_Edit
    if (InStr(cur, "Example:")) {
        GuiControl,, WB_Edit,
    }
}
Return

WB_Spy:
{
    ; Build the path to WindowSpy.ahk relative to Scriptsmith.exe
    spy := A_ScriptDir "\..\Window spy\WindowSpy.exe"

    ; Normalize the path
    spy := RegExReplace(spy, "[/\\]+", "\")

    if FileExist(spy) {
        Run, %spy%
    } else {
        MsgBox, 48, Window Spy Not Found
            , Could not find:`n%spy%`n`nMake sure WindowSpy.ahk is in the "Window spy" folder.
    }
    return
}

WB_Save:
{
    global WB_CurrentKey

    key := WB_CurrentKey
    if (key = "")
    {
        Gui, 3:Hide
        return
    }

    it := GetItem(key)
    if (!it)
    {
        Gui, 3:Hide
        return
    }

    Gui, 3:Default
    GuiControlGet, txt,, WB_Edit
    Gui, 1:Default

    apps := []
    txt := RegExReplace(txt, "\r\n|\r", "`n")

    Loop, Parse, txt, `n
    {
        v := Str_Trim(A_LoopField)
        if (v != "")
            apps.Push(v)
    }

    it.apps := apps
    Gui, 3:Hide
}
Return

WB_Cancel:
    Gui, 3:Hide
Return

3GuiEscape:
3GuiClose:
    Gui, 3:Hide
Return



; ==========================================
; File Locking & CSV Safety
; ==========================================
; Ensures the CSV is not open in Excel or locked by another process.

Csv_IsLocked(path) {
    f := FileOpen(path, "rw")
    if (f) {
        f.Close()
        return false
    }
    return true
}

Excel_LockFileExists(path) {
    SplitPath, path, name, dir
    lock := dir "\~$" name
    return !!FileExist(lock)
}

EnsureCsvClosed(path, title := "") {
    if (title = "")
        title := "File In Use"

    if !(Csv_IsLocked(path) || Excel_LockFileExists(path))
        return 1

    loop
    {
        MsgBox, 53, %title%, % "The CSV appears to be open in another program (likely Excel).`r`n`r`n"
            . "Please close it, then click Retry.`r`n`r`nPath:`r`n" path

        IfMsgBox, Retry
        {
            if !(Csv_IsLocked(path) || Excel_LockFileExists(path))
                return 1
        }
        else
        {
            return 0
        }
    }
}



; ==========================================
; Exit Handlers
; ==========================================
; Ensures consistent exit behavior.

ExitAppNow:
GuiClose:
GuiEscape:
    ExitApp
Return