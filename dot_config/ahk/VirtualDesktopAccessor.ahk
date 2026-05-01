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

IsWindowOnCurrentVirtualDesktop(hwnd) {
    global IsWindowOnCurrentVirtualDesktopProc
    return DllCall(IsWindowOnCurrentVirtualDesktopProc, "Ptr", hwnd, "Int")
}

IsWindowOnDesktopNumber(hwnd, num) {
    global IsWindowOnDesktopNumberProc
    return DllCall(IsWindowOnDesktopNumberProc, "Ptr", hwnd, "Int", num, "Int")
}
IsPinnedWindow(hwnd) {
    global IsPinnedWindowProc
    return DllCall(IsPinnedWindowProc, "Ptr", hwnd, "Int")
}

GetCurrentDesktopNumber() {
    global GetCurrentDesktopNumberProc
    return DllCall(GetCurrentDesktopNumberProc, "Int")
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
      return
    }
      logFile := A_ScriptDir "\ahk_debug.log"
      timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
      sep := "================================================================`n"
      log := sep
      log .= "TIME: " timestamp "  →  Desktop(" num ")`n"

      ; 切换前所有窗口
      log .= "[PRE-SWITCH ALL WINDOWS]`n"
      log .= GetAllWindowsInfo()
      log .= sep

      GoToDesktopNumber(num)

      ; 切换后快照
      log .= "[POST-SWITCH ACTIVE WINDOW]`n"
      log .= GetWindowInfo(WinExist("A"))
      log .= sep

      ; 切换后所有窗口
      log .= "[POST-SWITCH ALL WINDOWS]`n"
      log .= GetAllWindowsInfo()
      log .= sep . "`n"

      FileAppend(log, logFile)

      hwnds := WinGetList()
      for hwnd in hwnds {
        if !IsWindowOnCurrentVirtualDesktop(hwnd)
          continue
        ; 排除 pin 到所有桌面的窗口（任务栏等）
        if IsPinnedWindow(hwnd)
          continue

        ; 获取进程名，排除企业微信等干扰进程
        try {
            procName := WinGetProcessName("ahk_id " hwnd)
        } catch {
            procName := ""
        }

        try {
          title := WinGetTitle("ahk_id " hwnd)
        } catch {
          title := ""
        }

        WinActivate("ahk_id " hwnd)
        break
      }
      return

}
GetWindowInfo(hwnd) {
  if !hwnd
    return "  (none)`n"

  info := "  hwnd       = " hwnd "`n"

  try {
    info .= "  title      = " WinGetTitle("ahk_id " hwnd) "`n"
  } catch  {
  }

  try {
    info .= "  proc       = " WinGetProcessName("ahk_id " hwnd) "`n"
  } catch  {
  }

  try {
    info .= "  pid        = " WinGetPID("ahk_id " hwnd) "`n"
  } catch  {
  }

  try {
    info .= "  class      = " WinGetClass("ahk_id " hwnd) "`n"
  } catch  {
  }

  try {
    minMax := WinGetMinMax("ahk_id " hwnd)
    minMaxStr := (minMax = 1) ? "1 (maximized)" : (minMax = -1) ? "-1 (minimized)" : "0 (normal)"
    info .= "  minMax     = " minMaxStr "`n"
  } catch  {
  }

  try {
    style := WinGetStyle("ahk_id " hwnd)
    info .= "  style      = 0x" Format("{:08X}", style) "`n"
    info .= "  WS_VISIBLE = " ((style & 0x10000000) ? "YES" : "NO") "`n"
    info .= "  WS_CHILD   = " ((style & 0x40000000) ? "YES" : "NO") "`n"
  } catch  {
  }

  try {
    exStyle := WinGetExStyle("ahk_id " hwnd)
    info .= "  exStyle    = 0x" Format("{:08X}", exStyle) "`n"
    info .= "  WS_EX_TOOL = " ((exStyle & 0x00000080) ? "YES" : "NO") "`n"
    info .= "  WS_EX_NOAC = " ((exStyle & 0x08000000) ? "YES" : "NO") "`n"
  } catch  {
  }

  try {
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    info .= "  pos        = x=" x " y=" y " w=" w " h=" h "`n"
  } catch  {
  }

  return info
}

GetAllWindowsInfo() {
  hwnds := WinGetList()
  info := "  total=" hwnds.Length "`n"
  info .= "--------------------------------`n"

  idx := 0
  for hwnd in hwnds {
    if !IsWindowOnCurrentVirtualDesktop(hwnd)
        continue
    ; 排除 pin 到所有桌面的窗口（任务栏等）
    if IsPinnedWindow(hwnd)
        continue
    idx++
    info .= "[" idx "] "

    try title := WinGetTitle("ahk_id " hwnd)
    catch
      title := ""

    ; 无标题窗口单行打印，减少噪音
    if (title = "") {
      try {
          proc := WinGetProcessName("ahk_id " hwnd)
      } catch {
          proc := "?"
      }

      try {
          cls := WinGetClass("ahk_id " hwnd)
      } catch {
          cls := "?"
      }
      info .= "hwnd=" hwnd " proc=" proc " class=" cls " (no title)`n"
      continue
    }

    info .= "`n"
    info .= GetWindowInfo(hwnd)
    info .= "--------------------------------`n"
  }

  return info
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

