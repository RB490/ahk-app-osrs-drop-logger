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

    id := SubStr(OutputAssociatedVar, InStr(OutputAssociatedVar, "#") + 1)
    obj := dropTable.GetDrop(id)
    
    tooltip, % obj.itemQuantity " x " obj.itemName
}