ExitFunc(ExitReason, ExitCode) {
    FileDelete, % PATH_SETTINGS
    FileAppend, % json.dump(settings,,2), % PATH_SETTINGS

    DROP_LOG.Save()
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