; ============================================
; text_case_editor.ahk
;
;drop down selection to insert symbols
;drop down selection to send highlighted text to google,dictionary,thesaurus
;drop sown selection to change the text case lower,higher,capitlize,sentance case
; ============================================
; created by - Jackson Boyle
;01/31/2026
;
;Revision - V0.0
; ============================================




#SingleInstance Force
#NoEnv
SendMode Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
SetTitleMatchMode, 2
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




SetKeyDelay, 0, 0

;BROWSER := "chrome.exe"
URL_GOOGLE     := "https://www.google.com/search?q="
URL_DICTIONARY := "https://www.dictionary.com/browse/"
URL_THESAURUS  := "https://www.thesaurus.com/browse/"

; --------------------------
; Symbols (flat list, ordered)
; --------------------------
symbols := {}
symbolOrder := [] ; to keep order consistent
; --- Status / Alerts ---
Sym("26A0", "Warning")
Sym("2757", "Red exclamation ")
Sym("274C", "Large red X")
Sym("2718", "Heavy ballot X")
Sym("2714", "Check mark")
Sym("2705", "Green check mark")

; --- Punctuation / Bars / Dashes ---
Sym("2015", "Horizontal bar")          ; -
Sym("2014", "Em dash")               ; —
Sym("2013", "En dash")               ; –

; --- Arrows ---
Sym("2190", "Left Arrow")
Sym("2192", "Right Arrow")
Sym("2191", "Up Arrow")
Sym("2193", "Down Arrow")
Sym("2194", "Left-Right Arrow")
Sym("2195", "Up-Down Arrow")
Sym("21B5", "Return symbol")
Sym("21BB", "Clockwise Arrow")
Sym("21BA", "Counterclockwise Arrow")

; --- Math / Comparison ---
Sym("2248", "Almost equal")            ; ˜
Sym("2260", "Not equal")
Sym("2265", "= (greater or equal)")    ; =
Sym("2264", "= (less or equal)")       ; =
Sym("00B1", "Plus/minus")              ; ±
Sym("00F7", "Division")                ; ÷
Sym("00B2", "Superscript 2")           ; ²
Sym("00B3", "Superscript 3")           ; ³

; --- Greek Letters / Technical ---
Sym("03B1", "Alpha (lowercase)")       ; a
Sym("03B2", "Beta (lowercase)")        ; ß
Sym("0394", "Delta (uppercase)")       ; ?
Sym("03B3", "Gamma (lowercase)")
Sym("03A3", "Sigma (uppercase)")       ; S
Sym("03C3", "Sigma (lowercase)")       ; s
Sym("1D70B", "pi (italic)")
Sym("03A9", "Omega (uppercase)")       ; O

; --- Units / Special Latin ---
Sym("00B0", "Degree")                  ; °
Sym("00B5", "Micro")                   ; µ
Sym("00F8", "O slash")                 ; ø
Sym("00DF", "Eszett")                  ; ß

; Track dynamic menu items for Before/After only
global insertSymbolBeforeAdded := false
global insertSymbolAfterAdded  := false
; New: map menu item text -> actual symbol
global menuItemToSymbol := {}

CreateSymbolMenus()
CreateMainMenu()
return


; ==========================
; HOTKEY: RButton + Space
; ==========================
#If Context_Allows("Text case editor menu")
~RButton & Space::
{
    if GetKeyState("LButton", "P") {
        pinWindow()
        return
    }

    if GetKeyState("RButton", "P") {
        highlightedText := GetSelectedText()

        ; Remove dynamic entries (Before/After) if present
        if (insertSymbolBeforeAdded) {
            Menu, InsertSymbolMenu, Delete, Insert Before Highlighted Text
            insertSymbolBeforeAdded := false
        }

        if (insertSymbolAfterAdded) {
            Menu, InsertSymbolMenu, Delete, Insert After Highlighted Text
            insertSymbolAfterAdded := false
        }

        ; Toggle case/search items depending on selection
        ToggleCaseItems(highlightedText != "")

        ; Add Before/After ONLY when there is selection
        if (highlightedText != "") {
            Menu, InsertSymbolMenu, Add, Insert Before Highlighted Text, :InsertSymbolBefore
            insertSymbolBeforeAdded := true
            Menu, InsertSymbolMenu, Add, Insert After Highlighted Text, :InsertSymbolAfter
            insertSymbolAfterAdded := true
        }
        ; Note: "Insert at Caret Position" is always present (static)

        Menu, CaseEditor, Show
    } else {
        Send, {RButton Up}
    }
}
return
#If

; ==========================
; Menus
; ==========================
CreateMainMenu() {
    Menu, CaseEditor, Add, Convert to lower case, MenuHandler, Disabled
    Menu, CaseEditor, Add, CONVERT TO UPPER CASE, MenuHandler, Disabled
    Menu, CaseEditor, Add, Convert To Capitalized Case, MenuHandler, Disabled
    Menu, CaseEditor, Add, Sentence format and eliminate double spaces, MenuHandler, Disabled
    Menu, CaseEditor, Add, Insert Symbol, :InsertSymbolMenu
    Menu, CaseEditor, Add
    Menu, CaseEditor, Add, Search text in Google, MenuHandler, Disabled
    Menu, CaseEditor, Add, Search text on dictionary.com, MenuHandler, Disabled
    Menu, CaseEditor, Add, Search text on thesaurus.com, MenuHandler, Disabled
    Menu, CaseEditor, Add, Ask Copilot to spell and grammar check, MenuHandler, Disabled
    Menu, CaseEditor, Add, Pin/Unpin Window, MenuHandler
    Menu, CaseEditor, Add, Close Menu, MenuHandler
}


CreateSymbolMenus() {
    global symbols
    global menuItemToSymbol
    global symbolOrder


    ; Populate the menus in the exact order they were defined via Sym(...)
    for idx, symbolChar in symbolOrder {
        label := symbols[symbolChar]
        itemText := symbolChar " — " label
        menuItemToSymbol[itemText] := symbolChar
        Menu, InsertSymbolBefore, Add, %itemText%, MenuHandler
        Menu, InsertSymbolAfter,  Add, %itemText%, MenuHandler
        Menu, InsertSymbolAtCaret,Add, %itemText%, MenuHandler
    }
    ; Create the “Insert Symbol” main submenu with a static caret entry
    Menu, InsertSymbolMenu, Add, Insert at Caret Position, :InsertSymbolAtCaret
    ; The Before/After entries will be added/removed dynamically based on selection
}


ToggleCaseItems(enable := true) {
    state := (enable ? "Enable" : "Disable")
    Menu, CaseEditor, %state%, Convert to lower case
    Menu, CaseEditor, %state%, CONVERT TO UPPER CASE
    Menu, CaseEditor, %state%, Convert To Capitalized Case
    Menu, CaseEditor, %state%, Sentence format and eliminate double spaces
    Menu, CaseEditor, %state%, Search text in Google
    Menu, CaseEditor, %state%, Search text on dictionary.com
    Menu, CaseEditor, %state%, Search text on thesaurus.com
    Menu, CaseEditor, %state%, Ask Copilot to spell and grammar check
}


; ==========================
; Menu Handler
; ==========================
MenuHandler:
{
    MenuItem   := A_ThisMenuItem
    MenuParent := A_ThisMenu
    highlightedText := GetSelectedText()
    ; Case/sentence actions require selection
    if (highlightedText != "") {
        if (MenuItem = "Convert to lower case")
            Convert_Lower()
        else if (MenuItem = "CONVERT TO UPPER CASE")
            Convert_Upper()
        else if (MenuItem = "Convert To Capitalized Case")
            Convert_Cap()
        else if (MenuItem = "Sentence format and eliminate double spaces")
            Sentence_Format()
    }

    ; Resolve symbol choice by menu item text
    global menuItemToSymbol
    symbol := ""
    if (menuItemToSymbol.HasKey(MenuItem))
        symbol := menuItemToSymbol[MenuItem]
    ; Symbol insertion
    if (symbol != "") {
        if (MenuParent = "InsertSymbolBefore")
            Insert_Symbol_Before(symbol)
        else if (MenuParent = "InsertSymbolAfter")
            Insert_Symbol_After(symbol)
        else if (MenuParent = "InsertSymbolAtCaret")
            ; *** Always just send the symbol at caret, regardless of selection ***
            Insert_Symbol_At_Caret(symbol)
    }

    ; Searches & Utilities
    else if (MenuItem = "Search text in Google") {
        Search(URL_GOOGLE)
    }

    else if (MenuItem = "Search text on dictionary.com") {
        Search(URL_DICTIONARY)
    }

    else if (MenuItem = "Search text on thesaurus.com") {
        Search(URL_THESAURUS)
    }

    else if (MenuItem = "Ask Copilot to spell and grammar check") {
        Open_Grammar_Guru()
    }

    else if (MenuItem = "Pin/Unpin Window") {
        pinWindow()
    }

    else if (MenuItem = "Close Menu") {
        ; no op
    }
}
return


; ==========================
; Case conversions
; ==========================
Convert_Lower()
{
    ModifyClipboard("Lower")
}


Convert_Upper()
{
    ModifyClipboard("Upper")
}


Convert_Cap()
{
    ModifyClipboard("Capitalize")
}



ModifyClipboard(conversionType) {
    Clip_Save := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.5
    if (ErrorLevel) {
        Clipboard := Clip_Save
        return
    }
    Send, {Delete}

    if (conversionType = "Lower")
        StringLower, out, Clipboard
    else if (conversionType = "Upper")
        StringUpper, out, Clipboard
    else if (conversionType = "Capitalize")
        StringUpper, out, Clipboard, T

    SendInput, %out%
    Len := StrLen(out)
    if (Len > 0)
        Send, +{Left %Len%}
    Clipboard := Clip_Save
}


; ==========================
; Sentence formatting
; ==========================
Sentence_Format() {
    Clip_Save := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.5
    if (ErrorLevel) {
        Clipboard := Clip_Save
        return
    }
    Send, {Delete}
    text := Clipboard
    text := RegExReplace(text, "\s+", " ")
    text := Trim(text)
    text := RegExReplace(text, "\s+([.,!?;:])", "$1")
    text := RegExReplace(text, "([.,!?;:])([^\s])", "$1 $2")
    if (text != "")
        text := RegExReplace(text, "^\s*\w", "$U0")
    text := RegExReplace(text, "(?<=[.!?]\s)(\w)", "$U1")
    SendInput, %text%
    Clipboard := Clip_Save
}



; ==========================
; Search helpers
; ==========================
Search(url)
{
    Browser := "chrome.exe"
    Save_Clipboard := ClipboardAll
    Clipboard := ""
    Send ^c
    ClipWait, 1
    if !ErrorLevel
    {
        Query := Clipboard
        ; Normalize whitespace and trim
        Query := Trim(RegExReplace(Query, "\s+", " "))
    }
    Clipboard := Save_Clipboard
    Save_Clipboard := ""  ; free memory
    ; IMPORTANT: Quote the URL argument so Chrome receives it as a single parameter.
    ; Browsers will handle spaces in the URL (convert to %20) just fine.
    Run, %Browser% "%url%%Query%"
}


; ==========================
; Grammar Guru
; ==========================
Open_Grammar_Guru() {
    Browser := "chrome.exe"
    URL_GRAMMAR_GURU :=
    Clipboard := ""
    Send, ^c
    ClipWait, 0.5
    highlightedText := Clipboard
    if (ErrorLevel || highlightedText = "")
        return

    newText := "spell and grammar check this( " highlightedText " )"
    Clipboard := newText
    Run, %Browser% https://m365.cloud.microsoft/chat?internalredirect=CCM&amp;auth=2
    SplashTextOn,450,, "Please wait while I ask copilot."
    Sleep 5000
    SendInput, ^v
    Sleep 10
    SendInput, {Enter}
    Sleep 50
    SplashTextOff
}


; ==========================
; Symbol insertion
; ==========================
Insert_Symbol_Before(symbol) {
    ClipSaved := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.3
    if (ErrorLevel) {
        Clipboard := ClipSaved
        return
    }
    highlightedText := Clipboard
    Send, {Delete}
    SendInput, % symbol highlightedText
    Clipboard := ClipSaved
}


Insert_Symbol_After(symbol) {
    ClipSaved := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.3
    if (ErrorLevel) {
        Clipboard := ClipSaved
        return
    }
    highlightedText := Clipboard
    Send, {Delete}
    SendInput, % highlightedText symbol
    Clipboard := ClipSaved
}


Insert_Symbol_At_Caret(symbol) {
    ; *** Only sends the symbol at caret, no clipboard, no selection needed ***
    SendInput, %symbol%
}


; ==========================
; Pin/Unpin
; ==========================
pinWindow(targetWindow := "A") {
    WinGet, hWnd, ID, %targetWindow%
    if !hWnd
        return
    WinGetTitle, title, ahk_id %hWnd%
    hasFlag := InStr(title, " - AlwaysOnTop")
    if (hasFlag) {
        newTitle := RegExReplace(title, " - AlwaysOnTop")
        WinSet, AlwaysOnTop, Off, ahk_id %hWnd%
        WinSetTitle, ahk_id %hWnd%,, %newTitle%
        Tip("Unpinned: " newTitle)
    } else {
        newTitle := title " - AlwaysOnTop"
        WinSet, AlwaysOnTop, On, ahk_id %hWnd%
        WinSetTitle, ahk_id %hWnd%,, %newTitle%
        Tip("Pinned: " newTitle)
    }
    KeyWait, Space
}



Tip(msg, ms := 2000) {
    ToolTip, %msg%
    SetTimer, __TipOff, -%ms%
}

__TipOff:
ToolTip
return


; ==========================
; Utilities
; ==========================
GetSelectedText() {
    ClipSaved := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.3
    selectedText := ErrorLevel ? "" : Clipboard
    Clipboard := ClipSaved
    return selectedText
}


Sym(hex, label) {
    global symbols, symbolOrder
    cp := "0x" hex
    ch := Chr(cp+0)
    symbols[ch] := label
    symbolOrder.Push(ch)  ; record insertion order
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;message_creater_start
;=================text_case_editor_and_highlight_search_public.ahk=======================
;Left button (mouse) + Right Button (mouse) + Space     ->     Pin/unpin window on top
; Right Button (mouse) + Space     ->     Text case editor menu (adjust text case,search text,insert symbol
;message_creater_end