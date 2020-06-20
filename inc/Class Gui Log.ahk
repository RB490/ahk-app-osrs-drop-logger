; save file in 'UTF-16 LE' format for symbols to display properly
class class_gui_log extends gui {
    Setup() {
        ; properties
        this.SetDefault() ; set as default for GuiControl
        this.Options("+labellogGui_") ; set as default for GuiControl
        this.marginSize := 5
        btnW := 100

        ; controls
        this.Add("tab3", "x" this.marginSize "", "")
        this._LoadDrops()

        DetectHiddenWindows, On ; for ControlGetPos
        ControlGetPos , tabX, tabY, tabW, tabH, SysTabControl321, % this.ahkid
        var = tabX = %tabX% %A_Tab% tabY = %tabY% %A_Tab% tabW = %tabW% %A_Tab% tabH = %tabH%

        this.Add("edit", "w" tabW  - this.marginSize + 3 " r1 section", "") ; selected drops

        g_logGui_BtnClearDrops := this.Add("button", "x+" this.marginSize " ys-1  w23 glogGui_BtnClearDrops", "X") ; btn clear drops
        this.Font("s18")
        g_logGui_btnUndo := this.Add("button", "x+" this.marginSize + 150 " w" 23 " h23 glogGui_BtnUndo", "⟲") ; btn undo
        g_logGui_btnRedo := this.Add("button", "x+" this.marginSize " w" 23 " h23 glogGui_BtnRedo", "⟳") ; btn redo
        this.Font("")

        this.Add("edit", "x" tabW + (this.marginSize * 2) + 27 " y" this.marginSize - 1 + 23 " w200 h" tabH - 22 " ReadOnly", "") ; drop log view

        g_logGui_btnKill := this.Add("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 2 + 23 " w23 h" tabH - 20 " glogGui_BtnKill", "+") ; btn add kill

        this.Font("s11")
        g_logGui_btnToggleDeath := this.AddGlobal("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 4 " w23 h23 glogGui_BtnToggleDeath", "Toggle Death") ; btn start / stop death

        this.Font("s16")
        g_logGui_btnToggleTrip := this.AddGlobal("button", "x+" this.marginSize " w" 98 " h23 glogGui_BtnToggleTrip", "►") ; btn start / stop trip

        this.Font("s16")
        g_logGui_btnNewTrip := this.Add("button", "x+" this.marginSize " w" 98 " h23 glogGui_BtnNewTrip", "► ►") ; btn new trip

        this.Font("")

        ; show
        this.Show()
        this.Update()

        HMENU := DllCall("GetSystemMenu", "Ptr", this.hwnd, "UInt", 0, "UPtr")
        DllCall("DeleteMenu", "Ptr", HMENU, "UInt", 0xF020, "UInt", 0) ; MINIMIZE
    }

    Update() {
        this.SetText("edit2", dropLog.Get())

        ; buttons
        If (dropLog.TripActive()) {
            this.Control("Enable", g_logGui_btnKill)
            this.Control("Enable", g_logGui_btnUndo)
            this.Control("Enable", g_logGui_btnRedo)
            this.SetText(g_logGui_btnToggleTrip, "■") ; end trip
            this.Control("Enable", g_logGui_btnToggleDeath)
        } else {
            this.Control("Disable", g_logGui_btnKill)
            this.Control("Disable", g_logGui_btnUndo)
            this.Control("Disable", g_logGui_btnRedo)
            this.SetText(g_logGui_btnToggleTrip, "►") ; start trip
            this.Control("Disable", g_logGui_btnToggleDeath)
        }

        If (dropLog.DeathActive()) {
            this.SetText(g_logGui_btnToggleDeath, "♥") ; end death
            this.Control("Disable", g_logGui_btnToggleTrip)
            this.Control("Disable", g_logGui_btnNewTrip)
        } else {
            this.SetText(g_logGui_btnToggleDeath, "☠") ; start death
            this.Control("Enable", g_logGui_btnToggleTrip)
            this.Control("Enable", g_logGui_btnNewTrip)
        }

        If (dropLog.redoActions.length())
            this.Control("Enable", g_logGui_btnRedo)
        else
            this.Control("Disable", g_logGui_btnRedo)

        If (dropLog.undoActions.length())
            this.Control("Enable", g_logGui_btnUndo)
        else
            this.Control("Disable", g_logGui_btnUndo)
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

    ToggleTrip() {
        If (dropLog.TripActive())
            dropLog.EndTrip()
        else
            dropLog.StartTrip()
        this.Update()
    }

    ToggleDeath() {
        If (dropLog.DeathActive())
            dropLog.EndDeath()
        else
            dropLog.StartDeath()
        this.Update()
    }

    NewTrip() {
        If (dropLog.TripActive())
            dropLog.EndTrip()
        dropLog.StartTrip()
        this.Update()
    }

    _LoadDrops() {
        this.Margin(0, 0)
        dropSize := 33 ; 33 is close to ingame inventory
        maxRowDrops := 8 ; after this amount of drops a new row is started

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

logGui_BtnClearDrops:
    logGui.ClearDrops()
return

logGui_BtnKill:
    logGui.AddKill()
return

logGui_BtnUndo:
    logGui.Undo()
return

logGui_BtnRedo:
    logGui.Redo()
return

logGui_BtnToggleDeath:
    logGui.ToggleDeath()
return

logGui_BtnToggleTrip:
    logGui.ToggleTrip()
return

logGui_BtnNewTrip:
    logGui.NewTrip()
return

logGui_BtnHandler:
    ; get active button text without spaces
    ControlGetFocus, OutputControl, A
    ControlGetText, OutputControlText, % OutputControl, A
    OutputControlText := StrReplace(OutputControlText, A_Space)

    If InStr(OutputControlText, "death")
        OutputControlText := "ToggleDeath"
    If InStr(OutputControlText, "NewTrip")
        OutputControlText := "ToggleTrip"

    ; call the class's method
    for a, b in class_gui_log.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
return

logGui_Close:
    ; call the class's method
    for a, b in class_gui_log.Instances 
		if (a = A_Gui+0)
			b["Events"]["_BtnClose"].Call()
return