; AutoHotkey v2 script
SetWorkingDir(A_ScriptDir)

; Path to the DLL, relative to the script
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")

GetDesktopCount() {
    global GetDesktopCountProc
    count := DllCall(GetDesktopCountProc, "Int")
    return count
}

MoveWindowUnderMouseToDesktop(number) {
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
    MouseGetPos(, , &hwnd)

    if hwnd {
        DllCall(MoveWindowToDesktopNumberProc, "Ptr", hwnd, "Int", number, "Int")
        DllCall(GoToDesktopNumberProc, "Int", number, "Int")
    }
}

GoToPrevDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is 0, go to last desktop
    if (current = 0) {
        MoveOrGotoDesktopNumber(last_desktop)
    } else {
        MoveOrGotoDesktopNumber(current - 1)
    }
    return
}

GoToNextDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is last, go to first desktop
    if (current = last_desktop) {
        MoveOrGotoDesktopNumber(0)
    } else {
        MoveOrGotoDesktopNumber(current + 1)
    }
    return
}

GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    DllCall(GoToDesktopNumberProc, "Int", num, "Int")
    return
}

MoveOrGotoDesktopNumber(num) {
    ; If user is holding down Mouse left button, move the window under mouse also
    if (GetKeyState("LButton","P")) {
        MoveWindowUnderMouseToDesktop(num)
    } else {
        GoToDesktopNumber(num)
          Sleep 50
          hwnds := WinGetList()
          for hwnd in hwnds {
title := WinGetTitle("ahk_id " hwnd)
         if (title != "" && title != "Program Manager") {
           WinActivate("ahk_id " hwnd)
             break
         }
          }

   }
    return
}

GetDesktopName(num) {
    global GetDesktopNameProc
    utf8_buffer := Buffer(1024, 0)
    ran := DllCall(GetDesktopNameProc, "Int", num, "Ptr", utf8_buffer, "Ptr", utf8_buffer.Size, "Int")
    name := StrGet(utf8_buffer, 1024, "UTF-8")
    return name
}
SetDesktopName(num, name) {
    global SetDesktopNameProc
    OutputDebug(name)
    name_utf8 := Buffer(1024, 0)
    StrPut(name, name_utf8, "UTF-8")
    ran := DllCall(SetDesktopNameProc, "Int", num, "Ptr", name_utf8, "Int")
    return ran
}
CreateDesktop() {
    global CreateDesktopProc
    ran := DllCall(CreateDesktopProc, "Int")
    return ran
}
RemoveDesktop(remove_desktop_number, fallback_desktop_number) {
    global RemoveDesktopProc
    ran := DllCall(RemoveDesktopProc, "Int", remove_desktop_number, "Int", fallback_desktop_number, "Int")
    return ran
}

; SetDesktopName(0, "It works! 🐱")

DllCall(RegisterPostMessageHookProc, "Ptr", A_ScriptHwnd, "Int", 0x1400 + 30, "Int")
OnMessage(0x1400 + 30, OnChangeDesktop)
OnChangeDesktop(wParam, lParam, msg, hwnd) {
    Critical(1)
    OldDesktop := wParam + 1
    NewDesktop := lParam + 1
    Name := GetDesktopName(NewDesktop - 1)

    ; Use Dbgview.exe to checkout the output debug logs
    OutputDebug("Desktop changed to " Name " from " OldDesktop " to " NewDesktop)
    ; TraySetIcon(".\Icons\icon" NewDesktop ".ico")
}

; #^!+1::MoveOrGotoDesktopNumber(0)
; #^!+2::MoveOrGotoDesktopNumber(1)
; #^!+3::MoveOrGotoDesktopNumber(2)
; #^!+4::MoveOrGotoDesktopNumber(3)
; #^!+5::MoveOrGotoDesktopNumber(4)
; #^!+q::MoveOrGotoDesktopNumber(5)
; #^!+w::MoveOrGotoDesktopNumber(6)
; #^!+e::MoveOrGotoDesktopNumber(7)
; #^!+r::MoveOrGotoDesktopNumber(8)
; #^!+t::MoveOrGotoDesktopNumber(9)
; #^!+x::MoveOrGotoDesktopNumber(10)
; #^!+c::MoveOrGotoDesktopNumber(11)
; #^!+v::MoveOrGotoDesktopNumber(12)
; #^!+b::MoveOrGotoDesktopNumber(13)


; F13 & 1:: MoveOrGotoDesktopNumber(0)
; F13 & 2:: MoveOrGotoDesktopNumber(1)
; F13 & 3:: MoveOrGotoDesktopNumber(2)
; F13 & 4:: MoveOrGotoDesktopNumber(3)
; F13 & 5:: MoveOrGotoDesktopNumber(4)
; F13 & 6:: MoveOrGotoDesktopNumber(5)

;LWin & q:: MoveOrGotoDesktopNumber(5)
;LWin & w:: MoveOrGotoDesktopNumber(6)
;LWin & e:: MoveOrGotoDesktopNumber(7)
;LWin & r:: MoveOrGotoDesktopNumber(8)
;LWin & t:: MoveOrGotoDesktopNumber(9)
;LWin & x:: MoveOrGotoDesktopNumber(10)
;LWin & c:: MoveOrGotoDesktopNumber(11)
;LWin & v:: MoveOrGotoDesktopNumber(12)
;LWin & b:: MoveOrGotoDesktopNumber(13)
;F14 UP:: GoToPrevDesktop()
;F15 UP:: GoToNextDesktop()
