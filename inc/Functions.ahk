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