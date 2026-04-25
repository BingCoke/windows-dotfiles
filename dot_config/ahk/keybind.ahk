#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "VirtualDesktopAccessor.ahk"

; 1. 将左Win键单独按下时映射为F13
;LWin::Send "{F13}"
;LWin::F13
;~LWin::vkE8
;~LWin::F13





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

usedKeys := "wqhjkl,r,c,v"
for char in StrSplit("abcdefghijklmnopqrstuvwxyz") {
    if !InStr(usedKeys, char)
        Hotkey("~F13 & " char, (*) => {})
}
