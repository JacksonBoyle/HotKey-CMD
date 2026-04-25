; ============================================
; context_engine.ahk
; Shared CSV Loader + Context Evaluation Engine
; ============================================
; Purpose: compiled library of custom ahk functions
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


;#Include ..\Library\context_engine.ahk
;Config := Csv_Load(csvPath)

global Config := {}
global __DBG := false
; ============================================
; Load CSV into Config object
; ============================================
Csv_Load(file) {
    cfg := {}
    cfg.__loaded_ok := false
    cfg.__version   := A_TickCount


    if !FileExist(file) {
        MsgBox, 16, Missing CSV File, The configuration file was not found:`n%file%
        return cfg
    }


    FileRead, text, %file%
    if (ErrorLevel) {
        MsgBox, 16, Read Error, Failed to read the configuration file:`n%file%
        return cfg
    }


    if (SubStr(text,1,3) = Chr(239) Chr(187) Chr(191))
        text := SubStr(text,4)

    lineNum := 0
    Loop, Parse, text, `n, `r
    {
        line := Trim(A_LoopField)
        if (line = "")
            continue

        line := StrReplace(line, Chr(160), " ")

        first := SubStr(line, 1, 1)
        if (first = ";" || first = "#")
            continue

        lineNum++
        delim := InStr(line, A_Tab) ? A_Tab : ","
        fields := StrSplit(line, delim)
        if (fields.MaxIndex() < 2)
            continue

        Loop % fields.MaxIndex() {
            fields[A_Index] := StrReplace(fields[A_Index], Chr(160), " ")
        }

        maybeLabel := ToLower(Trim(Csv_RemoveQuotes(fields[2])))
        if (lineNum = 1 && maybeLabel = "label")
            continue

        stateStr := ToLower(Trim(Csv_RemoveQuotes(fields[1])))
        enabled := IsTruthy(stateStr)

        label := maybeLabel
        if (label = "")
            continue

        scopeRaw := ""
        if (fields.MaxIndex() >= 5)
            scopeRaw := ToLower(Trim(Csv_RemoveQuotes(fields[5])))
        scope := NormalizeScope(scopeRaw)

        appsSet := {}
        if (fields.MaxIndex() >= 8) {
            idx := 8
            while (idx <= fields.MaxIndex()) {
                v := Trim(Csv_RemoveQuotes(fields[idx]))
                if (v != "") {
                    k := StripExeSuffix(NormalizeExe(v))
                    if (k != "")
                        appsSet[k] := true
                }
                idx++
            }
        }

        cfg[label] := { enabled: enabled
                      , scope:   scope
                      , apps:    appsSet }
    }

    cfg.__loaded_ok := true
    return cfg
}

__HideTip9() {
    ToolTip,,,,9
}

; ============================================
; Context evaluation engine
; ============================================
Context_Allows(label) {
    global Config, __DBG
    static cache := {}

    if (!IsObject(Config))
        return false

    key := ToLower(Trim(label))
    row := Config[key]

    ; Feature disabled?
    if (!IsObject(row) || !row.enabled)
        return false

    ; Cache key = (label + hwnd + version)
    WinGet, hwnd, ID, A
    ver := Config.__version

    c := cache[key]
    if (IsObject(c) && c.hwnd = hwnd && c.version = ver)
        return c.allowed

    exe := GetActiveProcessNameCached()
    scope := row.scope

    ; Evaluate scope rules
    if (scope = "always") {
        allowed := true
    } else {
        inSet := AppInSet(exe, row.apps)
        allowed := (scope = "exclude") ? !inSet
                : (scope = "include") ?  inSet
                : false
    }

    ; Optional debug overlay
    if (__DBG) {
        ToolTip, % "label=" key "`nexe=" exe "`nscope=" scope "`nallowed=" allowed, 20, 20, 9
        SetTimer, __HideTip9, -900
    }

    cache[key] := { hwnd: hwnd, version: ver, allowed: allowed }
    return allowed
}



; ============================================
; Cached active EXE lookup
; ============================================
GetActiveProcessNameCached() {
    static lastHwnd := 0
    static lastExe  := ""

    WinGet, hwnd, ID, A
    if (hwnd != lastHwnd) {
        lastHwnd := hwnd
        if (!hwnd) {
            lastExe := ""
        } else {
            WinGet, pid, PID, ahk_id %hwnd%
            if (!pid) {
                lastExe := ""
            } else {
                WinGet, exe, ProcessName, ahk_pid %pid%
                lastExe := ToLower(Trim(exe))
            }
        }
    }
    return lastExe
}

; ============================================
; App filtering helpers
; ============================================
AppInSet(exe, set) {
    if (!IsObject(set))
        return false
    ex := StripExeSuffix(exe)
    return !!set[ex]
}

NormalizeExe(name) {
    n := Trim(Csv_RemoveQuotes(name))
    n := ToLower(n)

    ; Remove path
    pos := 0
    Loop, Parse, n
    {
        ch := A_LoopField
        if (ch = "/" || ch = "\")
            pos := A_Index
    }
    if (pos > 0)
        n := SubStr(n, pos+1)

    ; Remove trailing commas/semicolons
    while (SubStr(n, 0) = "," || SubStr(n, 0) = ";")
        n := RTrim(n, ",; ")

    return n
}

StripExeSuffix(s) {
    s := ToLower(Trim(s))
    if (SubStr(s, -3) = ".exe")
        s := SubStr(s, 1, StrLen(s)-4)
    return s
}

; ============================================
; String helpers
; ============================================
Trim(s) {
    return RegExReplace(RegExReplace(s, "^\s+"), "\s+$")
}

ToLower(s) {
    t := s
    StringLower, t, t
    return t
}

Csv_RemoveQuotes(s) {
    s := Trim(s)
    if (SubStr(s,1,1) = """" && SubStr(s,0) = """")
        s := SubStr(s,2,StrLen(s)-2)
    return s
}

; ============================================
; Scope normalization
; ============================================
NormalizeScope(s) {
    s := ToLower(Trim(s))

    if (s = "" || InStr(s, "always"))
        return "always"

    if (s = "exclude" || s = "exclusive" || InStr(s, "excluding"))
        return "exclude"

    if (s = "include" || s = "inclusive" || InStr(s, "only"))
        return "include"

    return "always"
}

IsTruthy(val) {
    v := ToLower(Trim(val))
    return (v = "true" || v = "1" || v = "yes" || v = "on")
}




; --------------------------------------------
; Returns the active labels for current script running used to end script if non ar active
; --------------------------------------------
GetRequiredContexts() {
    values := []

    ; Read script as-is (works even with UTF-16 because we parse line-by-line)
    FileRead, scriptText, %A_ScriptFullPath%
    if ErrorLevel
        return values

    Loop, Parse, scriptText, `n, `r
    {
        line := A_LoopField

        ; Find "Context_Allows("
        start := InStr(line, "Context_Allows(")
        if (!start)
            continue

        ; Move past the function name
        start += StrLen("Context_Allows(")

        ; Find the closing parenthesis
        end := InStr(line, ")", false, start)
        if (!end)
            continue

        ; Extract the inside of Context_Allows(...)
        inner := SubStr(line, start, end - start)

        ; Extract quoted strings inside the parentheses
        pos := 1
        while RegExMatch(inner, """([^""]+)""", m, pos) {
            label := m1
            if !(label = "")
                values.Push(label)
            pos := m.Pos + m.Len
        }
    }

    return values
}


; --------------------------------------------
; Function to check required contexts used to exist script if no labels are active
; --------------------------------------------
;CheckRequiredContexts(requiredList) {
    ;for each, label in requiredList {
    ;    if (Context_Allows(label))
   ;         return true
  ;  }
 ;   return false
;}

CheckRequiredContexts(requiredList) {
    global Config
    for each, label in requiredList {
        key := ToLower(Trim(label))
        row := Config[key]
        ; If the label exists in CSV and 'enabled' is true, keep script alive
        if (IsObject(row) && row.enabled)
            return true
    }
    return false
}




; ============================================================
; WINDOW REOPEN LOGIC
; ============================================================
Safe_Reopen(winTitle, exePath) {
    if WinExist(winTitle) {
        WinActivate
        return
    }
    Safe_Run(exePath)
}

Open_Folder(winTitle, exePath) {
    if WinExist(winTitle) {
        WinActivate
        return
    }
    Safe_Folder_Open(exePath)
}


; ============================================================
; DEPTH-LIMITED RECURSIVE SEARCH
; ============================================================
FindRecursiveLimited(base, name, isFile, maxDepth, currentDepth := 0) {
    if (currentDepth > maxDepth)
        return ""

    ; Skip system folders
  ;  skip := ["Windows", "Program Files", "Program Files (x86)", "ProgramData", "$Recycle.Bin", "System Volume Information"]
   ; for _, bad in skip
    ;    if (InStr(base, "\" bad))
     ;       return ""

    ; Search this level
    Loop, Files, %base%\*.*, FD
    {
        if (A_LoopFileName = name)
            return A_LoopFileFullPath
    }

    ; Search subdirectories
    Loop, Files, %base%\*.*, D
    {
        ; Skip hidden/system dirs
        if (A_LoopFileAttrib ~= "H|S")
            continue

        found := FindRecursiveLimited(A_LoopFileFullPath, name, isFile, maxDepth, currentDepth + 1)
        if (found != "")
            return found
    }

    return ""
}


; ============================================================
; FOLDER-ONLY VERSION
; ============================================================
Safe_Folder_Open(exePath) {
    global FolderCache

    if (FolderCache.HasKey(exePath)) {
        cached := FolderCache[exePath]
        if FileExist(cached) {
            Run, %cached%
            return
        }
        FolderCache.Delete(exePath)
    }

    if (SubStr(exePath, 1, 6) = "shell:" || InStr(exePath, "::{")) {
        FolderCache[exePath] := exePath
        Run, %exePath%
        return
    }

    if FileExist(exePath) {
        FolderCache[exePath] := exePath
        Run, %exePath%
        return
    }

    original := exePath
    folderName := SubStr(original, InStr(original, "\", false, 0) + 1)
    temp := original

    Loop, 3 {
        pos := InStr(temp, "\", false, 0)
        if (pos = 0)
            break

        temp := SubStr(temp, 1, pos - 1)

        if (StrLen(temp) <= 3)
            break

        Loop, Files, %temp%\*.*, D
        {
            if (A_LoopFileName = folderName) {
                FolderCache[exePath] := A_LoopFileFullPath
                Run, %A_LoopFileFullPath%
                return
            }
        }

        found := FindRecursiveLimited(temp, folderName, false, 3)
        if (found != "") {
            FolderCache[exePath] := found
            Run, %found%
            return
        }
    }

    MsgBox, 48, Folder Missing, Could not locate:`n%exePath%
}


; ============================================================
; FILE + FOLDER VERSION
; ============================================================
Safe_Run(targetPath) {
    global FolderCache

    ; 1. CACHE VALIDATION
    if (FolderCache.HasKey(targetPath)) {
        cached := FolderCache[targetPath]
        if FileExist(cached) {
            _Internal_Run(cached) ; Use helper to handle PS1 logic
            return
        }
        FolderCache.Delete(targetPath)
    }

    ; 2. Shell folders
    if (SubStr(targetPath, 1, 6) = "shell:" || InStr(targetPath, "::{")) {
        FolderCache[targetPath] := targetPath
        Run, %targetPath%
        return
    }

    ; Detect file vs folder
    isFile := RegExMatch(targetPath, "\.[A-Za-z0-9]+$")
    fileName := SubStr(targetPath, InStr(targetPath, "\", false, 0) + 1)

    ; 3. Direct hit
    if FileExist(targetPath) {
        FolderCache[targetPath] := targetPath
        _Internal_Run(targetPath)
        return
    }

    ; 4. SMART SEARCH
    original := targetPath
    temp := original

    Loop, 3 {
        pos := InStr(temp, "\", false, 0)
        if (pos = 0)
            break
        temp := SubStr(temp, 1, pos - 1)
        if (StrLen(temp) <= 3)
            break

        Loop, Files, %temp%\*.*, FD
        {
            if (A_LoopFileName = fileName) {
                FolderCache[targetPath] := A_LoopFileFullPath
                _Internal_Run(A_LoopFileFullPath)
                return
            }
        }

        found := FindRecursiveLimited(temp, fileName, isFile, 3)
        if (found != "") {
            FolderCache[targetPath] := found
            _Internal_Run(found)
            return
        }
    }

    MsgBox, 48, Not Found, Could not locate:`n%targetPath%
}

; Helper function to handle the actual execution logic
_Internal_Run(path) {
    ; Check if it's a PowerShell script
    if (SubStr(path, -3) = ".ps1") {
        ; Launch with PowerShell, bypassing execution policy, and keeping the window open if needed
        ; Use -NoProfile for faster startup
        Run, powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%path%"
    } else {
        ; Standard run for everything else (Folders, Exes, etc.)
        Run, %path%
    }
}
