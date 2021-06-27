; wingetpos workaround see https://www.autohotkey.com/boards/viewtopic.php?t=9093
; purpose = Retrieves the dimensions of the bounding rectangle of the specified window.
WinGetPos(hWnd, ByRef x := "", ByRef y := "", ByRef Width := "", ByRef Height := "", Mode := 0) {
	VarSetCapacity(WRECT, 8 * 2, 0), i := {}
	, h := DllCall("User32.dll\GetWindowRect", "Ptr", hWnd, "Ptr", &WRECT)
	if (Mode=1||Mode=3)
		VarSetCapacity(CRECT, 8 * 2, 0)
		, h := DllCall("User32.dll\GetClientRect", "Ptr", hWnd, "Ptr", &CRECT)
	if (Mode=2||Mode=3)
		DllCall("User32.dll\ClientToScreen", "Ptr", hWnd, "Ptr", &WRECT)
		, DllCall("User32.dll\ClientToScreen", "Ptr", hWnd, "Ptr", &CRECT)
	i.x := x := NumGet(WRECT, 0, "Int"), i.y := y := NumGet(WRECT, 4, "Int")
	, i.h := i.Height := Height := NumGet(Mode=1||Mode=3?CRECT:WRECT, 12, "Int") - (Mode=1||Mode=3?0:y)
	, i.w := i.Width := Width := NumGet(Mode=1||Mode=3?CRECT:WRECT,  8, "Int") - (Mode=1||Mode=3?0:x)
	return i, ErrorLevel := !h
}