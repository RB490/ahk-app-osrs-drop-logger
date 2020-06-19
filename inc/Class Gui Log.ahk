class class_gui_logger extends gui {
    Setup() {
        ; events
        this.Events["_BtnClear"] := this.ClearDrops.Bind(this)
        this.Events["_Btn+Kill"] := this.AddKill.Bind(this)
        this.Events["_BtnUndo"] := this.Undo.Bind(this)
        this.Events["_BtnRedo"] := this.Redo.Bind(this)
        this.Events["_BtnStartTrip"] := this.StartTrip.Bind(this)
        this.Events["_BtnEndTrip"] := this.EndTrip.Bind(this)
        this.Events["_BtnStartDeath"] := this.StartDeath.Bind(this)
        this.Events["_BtnEndDeath"] := this.EndDeath.Bind(this)
        this.Events["_BtnClose"] := this.Close.Bind(this)

        ; properties
        this.SetDefault() ; set as default for GuiControl
        this.Options("+labellogGui_") ; set as default for GuiControl
        this.marginSize := 10

        ; controls
        this.Add("tab3", "", "")
        this._LoadDrops()

        DetectHiddenWindows, On ; for ControlGetPos
        ControlGetPos , tabX, tabY, tabW, tabH, SysTabControl321, % this.ahkid
        var = tabX = %tabX% %A_Tab% tabY = %tabY% %A_Tab% tabW = %tabW% %A_Tab% tabH = %tabH%
        this.Add("edit", "w" tabW + 165 " r1", "")

        this.Add("button", "x+" this.marginSize " glogGui_BtnHandler", "Clear")

        this.Add("edit", "x" tabW + (this.marginSize * 2) " y" this.marginSize - 1 " w200 h" tabH, "")

        this.Add("button", "x10 glogGui_BtnHandler", "+ Kill")
        this.Add("button", "glogGui_BtnHandler", "Undo")
        this.Add("button", "glogGui_BtnHandler", "Redo")
        this.Add("button", "glogGui_BtnHandler", "Start trip")
        this.Add("button", "glogGui_BtnHandler", "End trip")
        this.Add("button", "glogGui_BtnHandler", "Start death")
        this.Add("button", "glogGui_BtnHandler", "End death")

        ; show
        this.Show()
        this.Update()

        ; dropLog.Debug()
    }

    Update() {
        this.SetText("edit2", dropLog.Get())

        ; buttons
        If (dropLog.TripActive()) {
            this.Control("Enable", "+ Kill")
            this.Control("Enable", "Undo")
            this.Control("Enable", "Redo")
            this.Control("Disable", "Start trip")
            this.Control("Enable", "End trip")
            this.Control("Enable", "Start death")
            this.Control("Enable", "End death")
        } else {
            this.Control("Disable", "+ Kill")
            this.Control("Disable", "Undo")
            this.Control("Disable", "Redo")
            this.Control("Enable", "Start trip")
            this.Control("Disable", "End trip")
            this.Control("Disable", "Start death")
            this.Control("Disable", "End death")
            return
        }

        If (dropLog.redoActions.length())
            this.Control("Enable", "Redo")
        else
            this.Control("Disable", "Redo")

        If (dropLog.undoActions.length())
            this.Control("Enable", "Undo")
        else
            this.Control("Disable", "Undo")

        If (dropLog.DeathActive()) {
            this.Control("Disable", "Start death")
            this.Control("Enable", "End death")
            this.Control("Disable", "End trip")
        } else {
            this.Control("Enable", "Start death")
            this.Control("Disable", "End death")
        }

        clipboard := json.dump(dropLog.obj,,2)
    }

    ClearDrops() {
        g_selectedDrops := {}
        this.SetText("Edit1")
    }

    AddKill() {
        result := dropLog.Add(g_selectedDrops)
        If !(result)
            return
        this.ClearDrops()
        this.Update()
    }

    Undo() {
        dropLog.Undo()
        this.Update()
    }

    Redo() {
        dropLog.Redo()
        this.Update()
    }

    StartTrip() {
        dropLog.StartTrip()
        this.Update()
    }

    EndTrip() {
        dropLog.EndTrip()
        this.Update()
    }

    StartDeath() {
        dropLog.StartDeath()
        this.Update()
    }

    EndDeath() {
        dropLog.EndDeath()
        this.Update()
    }

    _LoadDrops() {
        this.Margin(0, 0)
        dropSize := 30 ; 27 is close to ingame inventory
        maxRowDrops := 10 ; after this amount of drops a new row is started

        loop % dropTable.obj.length() {
            tab := dropTable.obj[A_Index].title
            drops := dropTable.obj[A_Index].drops

            ; add tab
            GuiControl,, SysTabControl321, % tab
            this.Tab(tab) ; Future controls are owned by the tab whose name starts with Name (not case sensitive).

            ; add drops
            rowDrops := 0
            loop % drops.length() {
                If (rowDrops = maxRowDrops)
                    rowDrops := 0

                If (drops[A_Index].name = "Nothing")
                    dropImg := A_ScriptDir "\res\img\Nothing.png"
                else
                    dropImg := g_path_itemImages "\" runeLiteApi.GetId(drops[A_Index].name) ".png"

                totalItems++
                dropVar := "g_vLogGuiItem#" totalItems

                If (A_Index = 1)
                    this.AddGlobal("picture", "x+0 section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop
                else if !(rowDrops)
                    this.AddGlobal("picture", "xs ys+" dropSize " section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop of a new row
                else
                    this.AddGlobal("picture", "xp+" dropSize "  w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; add normal drop

                rowDrops++
            }
        }

        this.Tab("") ; Future controls are not part of any tab control.
        this.Margin(this.marginSize, this.marginSize) ; restore margin size
    }

    Close() {
        exitapp
    }
}

logGui_BtnHandler:
    ; get active button text without spaces
    ControlGetFocus, OutputControl, A
    ControlGetText, OutputControlText, % OutputControl, A
    OutputControlText := StrReplace(OutputControlText, A_Space)

    ; call the class's method
    for a, b in class_gui_logger.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
return

logGui_Close:
    ; call the class's method
    for a, b in class_gui_logger.Instances 
		if (a = A_Gui+0)
			b["Events"]["_BtnClose"].Call()
return