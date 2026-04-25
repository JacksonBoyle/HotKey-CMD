; ============================================
; Paste_fix_function.ahk
; Shared CSV Loader + Context Evaluation Engine
; ============================================
; Purpose: custome pasted function to remove the "" from
; copied file path in files explorer.
;
;created by - Jackson Boyle
;01/25/2026
;
;Revision - V0.0
; ============================================
; --------------------------------------------
;menu tray icon
; --------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\..\..\Images\Tray_Icon.ico




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