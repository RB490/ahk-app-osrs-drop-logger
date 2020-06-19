ExitFunc(ExitReason, ExitCode) {
    FileDelete, % g_path_settings
    FileAppend, % json.dump(settings,,2), % g_path_settings

    dropLog.Save()
}

OnWM_LBUTTONDOWN(wParam, lParam, msg, hWnd) {
    MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl
    GuiControlGet, OutputAssociatedVar, Name, % OutputVarControl

    If !(OutputAssociatedVar) {
        tooltip
        return
    }

    If !(dropLog.TripActive()) {
        tooltip No trip started!
        SetTimer, disableTooltip, -250
        return
    }

    id := SubStr(OutputAssociatedVar, InStr(OutputAssociatedVar, "#") + 1)
    obj := dropTable.GetDrop(id)
    Obj.Delete("iconHtml")
    Obj.Delete("highAlchPrice")
    Obj.Delete("price")
    Obj.Delete("rarity")

    If InStr(obj.quantity, "#")
        obj.quantity := quantityGui.Get(obj)
    If !(obj.quantity)
        return

    g_selectedDrops.push(obj)

    loop % g_selectedDrops.length()
        drops .= g_selectedDrops[A_Index].quantity " x " g_selectedDrops[A_Index].name ", "
    drops := RTrim(drops, ", ")

    logGui.SetText("edit1", drops)
}

ObjFullyClone(obj)
{
	nobj := obj.Clone()
	for k,v in nobj
		if IsObject(v)
			nobj[k] := A_ThisFunc.(v)
	return nobj
}