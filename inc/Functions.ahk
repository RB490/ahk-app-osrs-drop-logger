ExitFunc(ExitReason, ExitCode) {
    FileDelete, % A_ScriptDir "\settings.json"
    FileAppend, % json.dump(settings,,2), % A_ScriptDir "\settings.json"
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
    Obj.Delete("itemHighAlch")
    Obj.Delete("itemImage")
    Obj.Delete("itemPrice")
    Obj.Delete("itemRarity")

    g_selectedDrops.push(obj)

    loop % g_selectedDrops.length()
        drops .= g_selectedDrops[A_Index].itemQuantity " x " g_selectedDrops[A_Index].itemName ", "
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