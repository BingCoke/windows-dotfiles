#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "VirtualDesktopAccessor.ahk"
SetWinDelay(1)




; ============================================================
;  MOD KEY CONFIG — 只改这里
;  可选值示例: "F13"  "F14"  "CapsLock"  "ScrollLock"
;             "XButton1"  "XButton2"  "Pause"
; ============================================================
global MOD_KEY  := "F13"
global isMovingWindow := false
global DEBUG_ENABLED := false

; 设置成 CapsLock 那么就设置系统永远不会被大小写锁定
if (MOD_KEY = "CapsLock")
    SetCapsLockState "AlwaysOff"

; ============================================================
;  辅助: 动态注册组合键
; ============================================================
_hk(suffix, fn) {
    Hotkey("~" MOD_KEY " & " suffix, fn)
}

; ============================================================
;  注册所有热键
; ============================================================

_hk("w", OpenTerminal)
_hk("Space", SendF14)
_hk("f", ToggleMaximize)
_hk("q", KillUnderMouse)
_hk("h", (*) => Send("{Left}"))
_hk("j", (*) => Send("{Down}"))
_hk("k", (*) => Send("{Up}"))
_hk("l", (*) => Send("{Right}"))
_hk("r", (*) => Send("{F5}"))
_hk("LButton", (*) => DragWindow())
_hk("RButton", (*) => ResizeWindow())

_hk("1", (*) => MoveOrGotoDesktopNumber(0))
_hk("2", (*) => MoveOrGotoDesktopNumber(1))
_hk("3", (*) => MoveOrGotoDesktopNumber(2))
_hk("4", (*) => MoveOrGotoDesktopNumber(3))
_hk("5", (*) => MoveOrGotoDesktopNumber(4))
_hk("6", (*) => MoveOrGotoDesktopNumber(5))

; mod key 单独按下时, 若鼠标已按住则触发拖动/缩放
Hotkey("~" MOD_KEY, ModKeyAlone)

; 屏蔽未使用的字母键
usedKeys := "wqhjklrcf"
for char in StrSplit("abcdefghijklmnopqrstuvwxyz") {
    if !InStr(usedKeys, char)
        _hk(char, (*) => {})
}

; ============================================================
;  具名回调函数
; ============================================================


ModKeyAlone(*) {
    global isMovingWindow
    if isMovingWindow
        return
    if GetKeyState("LButton", "P")
        DragWindow()
    else if GetKeyState("RButton", "P")
        ResizeWindow()
}

OpenTerminal(*) {
    Run "alacritty.exe",,,  &pid
    WinWait "ahk_pid " pid
    WinActivate "ahk_pid " pid
    WinMoveTop "ahk_pid " pid
}

SendF14(*) {
    Send("{F14}")
}

ToggleMaximize(*) {
    hwnd := WinExist("A")
    if !hwnd
        return
    if (WinGetMinMax(hwnd) = 1)
        WinRestore(hwnd)
    else
        WinMaximize(hwnd)
}

KillUnderMouse(*) {
    MouseGetPos(, , &hwnd)
    if hwnd
        WinKill("ahk_id " hwnd)
}

; ============================================================
;  窗口拖动 / 缩放
; ============================================================

UnMaximizeWindow(hwnd, winX, winY, winW, winH) {
    wp := Buffer(44, 0)
    NumPut("UInt", 44, wp, 0)
    DllCall("GetWindowPlacement", "Ptr", hwnd, "Ptr", wp)
    NumPut("UInt", 1,        wp,  8)
    NumPut("Int",  winX,     wp, 28)
    NumPut("Int",  winY,     wp, 32)
    NumPut("Int",  winX + winW, wp, 36)
    NumPut("Int",  winY + winH, wp, 40)
    DllCall("SetWindowPlacement", "Ptr", hwnd, "Ptr", wp)
}

DragWindow() {
    global isMovingWindow
    CoordMode("Mouse", "Screen")
    if isMovingWindow
        return
    isMovingWindow := true
    MouseGetPos(&startX, &startY, &hwnd)
    WinActivate("ahk_id " hwnd)

    ; Activate 可能导致原窗口消失，重新取鼠标下的窗口
    MouseGetPos(,, &hwndAfter)
    if (hwndAfter != hwnd) {
        ; 原窗口没了（菜单/浮层被关掉），用新窗口
        ; 新窗口此时可能已经是正确的宿主窗口了
        hwnd := hwndAfter
    }

    WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    if WinGetMinMax("ahk_id " hwnd) = 1
        UnMaximizeWindow(hwnd, winX, winY, winW, winH)
    while GetKeyState("LButton", "P") {
        MouseGetPos(&currX, &currY)
        WinMove(winX + currX - startX, winY + currY - startY,,, hwnd)
    }
    isMovingWindow := false
}

ResizeWindow() {
    global isMovingWindow
    CoordMode("Mouse", "Screen")
    if isMovingWindow
        return
    isMovingWindow := true
    MouseGetPos(&startX, &startY, &hwnd)
    WinGetPos(&winX, &winY, &winW, &winH, hwnd)

    style := WinGetStyle("ahk_id " hwnd)
    if !(style & 0x40000) {
        isMovingWindow := false
        return
    }

    if WinGetMinMax("ahk_id " hwnd) = 1
        UnMaximizeWindow(hwnd, winX, winY, winW, winH)

    resizeRight  := (startX >= winX + winW / 2)
    resizeBottom := (startY >= winY + winH / 2)
    minW := 100
    minH := 100

    while GetKeyState("RButton", "P") {
        MouseGetPos(&curX, &curY)
        deltaX := curX - startX
        deltaY := curY - startY
        newX := winX, newY := winY
        newW := winW, newH := winH
        if resizeRight
            newW := Max(winW + deltaX, minW)
        else {
            newW := Max(winW - deltaX, minW)
            newX := winX + winW - newW
        }
        if resizeBottom
            newH := Max(winH + deltaY, minH)
        else {
            newH := Max(winH - deltaY, minH)
            newY := winY + winH - newH
        }
        WinMove(newX, newY, newW, newH, hwnd)
    }
    isMovingWindow := false
}

