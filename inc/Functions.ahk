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