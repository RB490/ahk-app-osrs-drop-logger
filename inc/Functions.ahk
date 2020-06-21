LoadSettings() {
    SETTINGS_OBJ := json.load(FileRead(PATH_SETTINGS))
        If !(IsObject(SETTINGS_OBJ)) {
            SETTINGS_OBJ := {}
            LoadDefaultSettings()
        }

    ; critical settings
    If (SETTINGS_OBJ.logGuiDropSize < MIN_DROP_SIZE) or (SETTINGS_OBJ.logGuiDropSize > MAX_DROP_SIZE)
        LoadDefaultSettings()
    
    If (SETTINGS_OBJ.logGuiMaxRowDrops < MIN_ROW_LENGTH) or (SETTINGS_OBJ.logGuiMaxRowDrops > MAX_ROW_LENGTH)
        LoadDefaultSettings()
}

LoadDefaultSettings() {
    SETTINGS_OBJ.logGuiDropSize := 33 ; 33 is close to ingame inventory
    SETTINGS_OBJ.logGuiMaxRowDrops := 8
}

ExitFunc(ExitReason, ExitCode) {
    LOG_GUI.SavePos()
    
    FileDelete, % PATH_SETTINGS
    FileAppend, % json.dump(SETTINGS_OBJ,,2), % PATH_SETTINGS

    DROP_LOG.Save()
}

; input = {string} 'encode' or 'decode'
; purpose = DROP_LOG.GetFormattedLog() uses timestamps to put events in the right order,
;   add A_MSec to prevent multiple actions in the same second overwriting eachother
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

    If InStr(obj.quantity, "#")
        obj.quantity := QUANTITY_GUI.Get(obj)
    If !(obj.quantity)
        return

    SELECTED_DROPS.push(obj)

    loop % SELECTED_DROPS.length()
        drops .= SELECTED_DROPS[A_Index].quantity " x " SELECTED_DROPS[A_Index].name ", "
    drops := RTrim(drops, ", ")

    LOG_GUI.SetText("edit1", drops)
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