;==============================================================
; Explorer Paste Behavior (AHK v1)
; - In File Explorer:
;     * Ctrl+V / Shift+Insert: paste WITHOUT outer quotes,
;       then Clipboard becomes a QUOTED path: "path"
;     * Right-click ? Paste: same behavior (menu-safe)
; - Outside Explorer: normal paste, Clipboard untouched
; - Copy actions are NEVER altered
; - Robust against clipboard change re-entrancy
;==============================================================
; created by -Jackson Boyle
;01/25/2026
;
;Revision - V0.0
; ============================================
#NoEnv
#SingleInstance, Force
#Warn
SetBatchLines, -1
ListLines, Off
SendMode, Input
SetTitleMatchMode, 2

;--------------------------
; State
;--------------------------
global _OrigBlob := ""            ; ClipboardAll backup (original text snapshot)
global _OrigText := ""            ; Original text (quoted)
global _CleanText := ""           ; Unquoted candidate (inner text)
global _HaveClean := false        ; True if candidate is valid for current clipboard
global _MenuWatchActive := false
global _InInternalChange := false ; Prevent handler re-entrancy during our own sets
global _LastPastedUnquoted := ""  ; Snapshot used after Ctrl+V/Shift+Insert
global _MenuPastedBasis := ""     ; Snapshot used after right-click menu


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
   ; MsgBox, 48, Disabled, All context rules for this script are disabled.`nExiting.
    ExitApp
}

;--------------------------
; Prepare only (no swaps on copy)
;--------------------------
OnClipboardChange("ClipChanged_Handler")
return

ClipChanged_Handler(Type) {
    global _OrigBlob, _OrigText, _CleanText, _HaveClean, _InInternalChange

    ; Ignore changes we make ourselves
    if (_InInternalChange)
        return

    ; Reset cached candidate each time the user/app changes the clipboard
    _ClearPrep()
    if (Type != 1)  ; only text clipboard
        return
    ClipWait, 0.1

    if (ErrorLevel)
        return
    txt := Clipboard

    if (txt = "")
        return
    ; If fully wrapped in outer quotes (allowing outer whitespace), cache candidate

    if (_UnwrapOuterQuotes(txt, cleaned)) {
        _OrigBlob := ClipboardAll
        _OrigText := txt
        _CleanText := cleaned
        _HaveClean := true
    }
}


;==============================================================
; Explorer-only paste overrides
;==============================================================
#If Context_Allows("Remove quotes from pasted file path")

; Ctrl+V and Shift+Insert -> paste unquoted, then set Clipboard to quoted form
^v::PasteUnquotedThenQuoteClipboard()
+Insert::PasteUnquotedThenQuoteClipboard()

; Right-click menu keys:
; - Temporarily swap clipboard to unquoted WHILE the context menu is open
; - After menu closes, set Clipboard to QUOTED path
~RButton::
~AppsKey::
+~F10::
    MaybeTemporarilyUnquoteForMenu()
return
#If

;==============================================================
; Functions
;==============================================================
PasteUnquotedThenQuoteClipboard() {
    global _OrigBlob, _OrigText, _CleanText, _HaveClean
    global _InInternalChange, _LastPastedUnquoted
    ; Only if we have an unquoted candidate and clipboard still matches original quoted text
    if (_HaveClean && Clipboard = _OrigText) {
        ; Snapshot the exact text we'll paste
        _LastPastedUnquoted := _CleanText
        ; 1) Temporarily set to UNQUOTED and paste
        _InInternalChange := true
        Clipboard := _LastPastedUnquoted
        ClipWait, 0.15
        _InInternalChange := false

        Send ^v
        Sleep, 40
        ; 2) Now set Clipboard to the QUOTED version of what we pasted
        _InInternalChange := true
        Clipboard := _EnsureQuoted(_LastPastedUnquoted)
        ClipWait, 0.15
        _InInternalChange := false
        return
    }
    ; Fallback: nothing to strip — paste normally
    Send ^v
}


MaybeTemporarilyUnquoteForMenu() {
    global _OrigBlob, _OrigText, _CleanText, _HaveClean
    global _InInternalChange, _MenuWatchActive, _MenuPastedBasis
    ; If we have a valid candidate and the clipboard hasn't changed, swap while menu is open
    if (_HaveClean && Clipboard = _OrigText) {
        _MenuPastedBasis := _CleanText
        _InInternalChange := true
        Clipboard := _MenuPastedBasis
        ClipWait, 0.1
        _InInternalChange := false
        ; Start watcher that finalizes clipboard to QUOTED once menu closes
        if (!_MenuWatchActive) {
            _MenuWatchActive := true
            SetTimer, __RestoreAfterMenu, 50
        }
    }
}

__RestoreAfterMenu:

{
    global _MenuWatchActive, _MenuPastedBasis, _InInternalChange
    ; When the system context menu (#32768) disappears, finalize clipboard
    if !WinExist("ahk_class #32768") {
        if (_MenuPastedBasis != "") {
            ; If clipboard still holds our unquoted version, convert it to quoted now
            if (Clipboard = _MenuPastedBasis) {
                _InInternalChange := true
                Clipboard := _EnsureQuoted(_MenuPastedBasis)
                ClipWait, 0.15
                _InInternalChange := false
            }
        }
        _MenuPastedBasis := ""
        _MenuWatchActive := false
        SetTimer, __RestoreAfterMenu, Off
    }
}
return

;-------------------------
; Helpers
;--------------------------
_UnwrapOuterQuotes(ByRef s, ByRef outClean) {

    ; Matches a single pair of outer quotes with optional surrounding whitespace
    ; Examples:
    ;   "foo"      -> foo
    ;   "A B"      -> A B
    ;   ""         -> (empty string)
    ; Does NOT change partial-quote cases like: a"b"c
    if (RegExMatch(s, "^\s*""(.*)""\s*$", m)) {
        outClean := m1
        return true
    }
    outClean := ""
    return false
}


_EnsureQuoted(s) {
    ; Trim outer whitespace and ensure exactly one pair of outer quotes
    s := RegExReplace(RegExReplace(s, "^\s+"), "\s+$")
    if (RegExMatch(s, "^"".*""$"))
        return s
    return """" . s . """"
}


_ClearPrep() {
    global _OrigBlob, _OrigText, _CleanText, _HaveClean
    _OrigBlob := ""
    _OrigText := ""
    _CleanText := ""
    _HaveClean := false
}