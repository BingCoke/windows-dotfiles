#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "VirtualDesktopAccessor.ahk"

isMovingWindow := false

SetWinDelay(0)


~F13 & w::{
    Run "alacritty.exe",,,  &pid
    WinWait "ahk_pid " pid
    WinActivate "ahk_pid " pid
    WinMoveTop "ahk_pid " pid
}                    ; 打开 Terminal

~F13 & Space::Send("{F14}")

~F13 & q::  ; Win+Q
{
    MouseGetPos(, , &hwnd)  ; 获取鼠标下的窗口句柄
    if hwnd {
        WinKill("ahk_id " hwnd)  ; 强制结束该窗口
    }
}

~F13 & h::Send("{Left}")

~F13 & j::Send("{Down}")
~F13 & k::Send("{Up}")
~F13 & l::Send("{Right}")

~F13 & r::Send("{F5}")



; 鼠标拖动窗口和resize窗口
~F13 & LButton::DragWindow()
~F13 & RButton::ResizeWindow()

~F13:: {
    global isMovingWindow

    if isMovingWindow
        return

    if GetKeyState("LButton", "P")
        DragWindow()
    else if GetKeyState("RButton", "P")
        ResizeWindow()
}

DragWindow() {
    global isMovingWindow

    CoordMode("Mouse", "Screen")

    if isMovingWindow
        return



    isMovingWindow := true
    MouseGetPos(&startX, &startY, &hwnd)
    WinActivate("ahk_id " hwnd)
    WinGetPos(&winX, &winY,,, hwnd)

    while GetKeyState("LButton", "P")  {
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

    ; 根据鼠标在窗口中的位置决定拖拽方向
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

~F13 & 1:: MoveOrGotoDesktopNumber(0)
~F13 & 2:: MoveOrGotoDesktopNumber(1)
~F13 & 3:: MoveOrGotoDesktopNumber(2)
~F13 & 4:: MoveOrGotoDesktopNumber(3)
~F13 & 5:: MoveOrGotoDesktopNumber(4)
~F13 & 6:: MoveOrGotoDesktopNumber(5)

usedKeys := "wqhjkl,r,c,v"
for char in StrSplit("abcdefghijklmnopqrstuvwxyz") {
    if !InStr(usedKeys, char)
        Hotkey("~F13 & " char, (*) => {})
}
