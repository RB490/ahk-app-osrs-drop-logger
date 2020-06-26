ExitFunc(ExitReason, ExitCode) {
    STATS_GUI.SavePos()
    LOG_GUI.SavePos()
    
    FileDelete, % PATH_SETTINGS
    FileAppend, % json.dump(DB_SETTINGS,,2), % PATH_SETTINGS

    ; prevent stats being messed up by trip ongoing while program isnt running
    If (A_IsCompiled) {
    If (DROP_LOG.TripActive())
        DROP_LOG.EndTrip()
    If (DROP_LOG.DeathActive())
        DROP_LOG.EndDeath()
    }
    DROP_LOG.Save()
}

Timer() {
    static startTime, timerActive
 
    If !(timerActive) {
        timerActive := true
        startTime := A_TickCount
    }
    else {
        timerActive := false
        elapsedTime := A_TickCount - startTime
        msgbox, 4160, , % A_ThisFunc ": " elapsedTime " milliseconds have elapsed."
    }
}

LoadSettings() {
    DB_SETTINGS := json.load(FileRead(PATH_SETTINGS))
    If !(IsObject(DB_SETTINGS)) {
        msgbox, 4160, , % A_ThisFunc ": Resetting settings"
        DB_SETTINGS := {}
    }

    ; critical settings
    If (DB_SETTINGS.logGuiDropSize < MIN_DROP_SIZE) or (DB_SETTINGS.logGuiDropSize > MAX_DROP_SIZE)
        DB_SETTINGS.logGuiDropSize := 33 ; 33 is close to ingame inventory
    
    If (DB_SETTINGS.logGuiMaxRowDrops < MIN_ROW_LENGTH) or (DB_SETTINGS.logGuiMaxRowDrops > MAX_ROW_LENGTH)
        DB_SETTINGS.logGuiMaxRowDrops := 8

    If (DB_SETTINGS.tablesMergeBelowX < MIN_TABLE_SIZE)
        DB_SETTINGS.tablesMergeBelowX := 27 ; 27 = rdt
}

; input = {string} 'encode' or 'decode'
; purpose = DROP_LOG.GetFormattedLog() uses timestamps to put events in the right order,
;   add A_MSec to prevent multiple actions in the same second overwriting eachother
; note = turns out decoding isn't necessary as 'EnvAdd' / 'EnvSub' ignore the added msecs
ConvertTimeStamp(encodeOrDecode, timeStamp) {
    sleep 1 ; wait 1 milisecond so actions in DROP_LOG.GetFormattedLog() don't execute on the same milisecond
    
    If (encodeOrDecode = "encode") {
        output := timeStamp A_MSec
    }

    If (encodeOrDecode = "decode")
        output := SubStr(timeStamp, 1, StrLen(timeStamp) - 3)

    return output
}

OnWM_LBUTTONDOWN(wParam, lParam, msg, hWnd) {
    MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl
    GuiControlGet, OutputAssociatedVar, Name, % OutputVarControl

    If !(OutputAssociatedVar) {
        tooltip
        return
    }

    If !(DROP_LOG.TripActive()) {
        tooltip No trip started!
        SetTimer, disableTooltip, -250
        return
    }
     If (DROP_LOG.DeathActive()) {
        tooltip You're dead!
        SetTimer, disableTooltip, -250
        return
    }

    id := SubStr(OutputAssociatedVar, InStr(OutputAssociatedVar, "#") + 1)
    obj := DROP_TABLE.GetDrop(id)
    Obj.Delete("iconHtml")
    Obj.Delete("highAlchPrice")
    Obj.Delete("price")
    Obj.Delete("rarity")

    If InStr(obj.quantity, "#") or InStr(obj.quantity, "-")
        obj.quantity := QUANTITY_GUI.Get(obj)
    If !(obj.quantity)
        return

    SELECTED_DROPS.push(obj)

    LOG_GUI.Update()
}

ObjFullyClone(obj)
{
	nobj := obj.Clone()
	for k,v in nobj
		if IsObject(v)
			nobj[k] := A_ThisFunc.(v)
	return nobj
}

; aligns to the left, or center if square button and size is correct
GuiButtonIcon(Handle, File, Index := 0, Size := 12, Margin := 1, Align := 5)
{
    Size -= Margin
    Psz := A_PtrSize = "" ? 4 : A_PtrSize, DW := "UInt", Ptr := A_PtrSize = "" ? DW : "Ptr"
    VarSetCapacity( button_il, 20 + Psz, 0 )
    NumPut( normal_il := DllCall( "ImageList_Create", DW, Size, DW, Size, DW, 0x21, DW, 1, DW, 1 ), button_il, 0, Ptr )
    NumPut( Align, button_il, 16 + Psz, DW )
    SendMessage, BCM_SETIMAGELIST := 5634, 0, &button_il,, AHK_ID %Handle%
    return IL_Add( normal_il, File, Index )
}

; centers together with text
SetButtonIcon(hButton, File, Index, Size := 16) {
    hIcon := LoadPicture(File, "h" . Size . " Icon" . Index, _)
    SendMessage 0xF7, 1, %hIcon%,, ahk_id %hButton% ; BM_SETIMAGE
}

AddCommas(n)

{

	StringSplit, d, n, .

	Loop, % StrLen(d1)

		x := SubStr(d1, 1-A_Index, 1), c := x . (A_Index>1 && !Mod(A_Index-1,3) ? "," : "") . c

	return c . (d0=2 ? "." d2 : "")

}

FormatSeconds(s) {
    t := A_YYYY A_MM A_DD 00 00 00
    t += s, seconds
    FormatTime, output, % t, HH:mm:ss
    return output
}

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