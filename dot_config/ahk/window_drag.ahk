#Requires AutoHotkey >=2.0-a
#SingleInstance force


~Alt & LButton:: {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&startX, &startY, &hwnd)
    WinGetPos(&winX, &winY,,, hwnd)
    SetWinDelay(3)

    while GetKeyState("LButton", "P") {
        MouseGetPos(&currX, &currY)
        WinMove(winX + currX - startX, winY + currY - startY,,, hwnd)
    }
}





~Alt & RButton:: {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&startX, &startY, &hwnd)
    WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    SetWinDelay(3)

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
}
