; save file in 'UTF-16 LE' format for symbols to display properly
class ClassGuiLog extends gui {
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
        If (tabH < 185) {
            tabH := 185
            ControlMove, SysTabControl321, , , , % tabH, % this.ahkid
        }

        this.Add("edit", "x" this.marginSize " y" (this.marginSize * 2) + tabH " w" tabW  - this.marginSize + 3 " r1 section ReadOnly", "") ; selected drops

        _BTN_CLEAR_DROPS := this.Add("button", "x+" this.marginSize " ys-1  w23 glogGui_BtnClearDrops", "X") ; btn clear drops
        this.Font("s18")
        _BTN_UNDO := this.Add("button", "x+" this.marginSize + 150 " w" 23 " h23 glogGui_BtnUndo", "⟲") ; btn undo
        _BTN_REDO := this.Add("button", "x+" this.marginSize " w" 23 " h23 glogGui_BtnRedo", "⟳") ; btn redo
        this.Font("")

        this.Add("edit", "x" tabW + (this.marginSize * 2) + 27 " y" this.marginSize - 1 + 23 " w200 h" tabH - 22 " ReadOnly", "") ; drop log view

        _BTN_KILL := this.Add("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 2 + 23 " w23 h" tabH - 20 " glogGui_BtnKill", "+") ; btn add kill

        this.Font("s11")
        _BTN_TOGGLE_DEATH := this.AddGlobal("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 4 " w23 h23 glogGui_BtnToggleDeath", "Toggle Death") ; btn start / stop death

        this.Font("s16")
        _BTN_TOGGLE_TRIP := this.AddGlobal("button", "x+" this.marginSize " w" 98 " h23 glogGui_BtnToggleTrip", "►") ; btn start / stop trip

        this.Font("s16")
        _BTN_NEW_TRIP := this.Add("button", "x+" this.marginSize " w" 98 " h23 glogGui_BtnNewTrip", "► ►") ; btn new trip

        this.Font("")

        ; show
        If !(SETTINGS_OBJ.guiLogX = "") and !(SETTINGS_OBJ.guiLogY = "")
            this.Show("x" SETTINGS_OBJ.guiLogX A_Space "y" SETTINGS_OBJ.guiLogY)
        else
            this.Show()
        this.Update()
    }

    Update() {
        this.SetText("edit2", DROP_LOG.GetFormattedLog())

        this.ClearDrops()

        ; buttons
        If (DROP_LOG.TripActive()) {
            this.Control("Enable", _BTN_TOGGLE_DEATH)
            this.Control("Enable", _BTN_KILL)
            this.Control("Enable", _BTN_CLEAR_DROPS)
            this.SetText(_BTN_TOGGLE_TRIP, "■") ; end trip
        } else {
            this.Control("Disable", _BTN_TOGGLE_DEATH)
            this.Control("Disable", _BTN_KILL)
            this.Control("Disable", _BTN_CLEAR_DROPS)
            this.SetText(_BTN_TOGGLE_TRIP, "►") ; start trip
        }

        If (DROP_LOG.DeathActive()) {
            this.SetText(_BTN_TOGGLE_DEATH, "♥") ; end death
            this.Control("Disable", _BTN_KILL)
            this.Control("Disable", _BTN_CLEAR_DROPS)
            this.Control("Disable", _BTN_NEW_TRIP)
            this.Control("Disable", _BTN_TOGGLE_TRIP)
        } else {
            this.SetText(_BTN_TOGGLE_DEATH, "☠") ; start death
            this.Control("Enable", _BTN_NEW_TRIP)
            this.Control("Enable", _BTN_TOGGLE_TRIP)
        }

        If (DROP_LOG.redoActions.length())
            this.Control("Enable", _BTN_REDO)
        else
            this.Control("Disable", _BTN_REDO)

        If (DROP_LOG.undoActions.length())
            this.Control("Enable", _BTN_UNDO)
        else
            this.Control("Disable", _BTN_UNDO)
    }

    ClearDrops() {
        SELECTED_DROPS := {}
        this.SetText("Edit1")
    }

    AddKill() {
        result := DROP_LOG.AddKill(SELECTED_DROPS)
        If !(result)
            return
        this.Update()
    }

    Undo() {
        DROP_LOG.Undo()
        this.Update()
    }

    Redo() {
        DROP_LOG.Redo()
        this.Update()
    }

    StartTrip() {
        DROP_LOG.StartTrip()
        this.Update()
    }

    EndTrip() {
        DROP_LOG.EndTrip()
        this.Update()
    }

    ToggleTrip() {
        DROP_LOG.ToggleTrip()
        this.Update()
    }

    ToggleDeath() {
        DROP_LOG.ToggleDeath()
        this.Update()
    }

    NewTrip() {
        DROP_LOG.NewTrip()
        this.Update()
    }

    _LoadDrops() {
        this.Margin(0, 0)
        dropSize := 33 ; 33 is close to ingame inventory
        maxRowDrops := 8 ; after this amount of drops a new row is started

        loop % DROP_TABLE.obj.length() {
            tab := DROP_TABLE.obj[A_Index].title
            drops := DROP_TABLE.obj[A_Index].drops

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
                    dropImg := PATH_ITEM_IMAGES "\" RUNELITE_API.GetId(drops[A_Index].name) ".png"

                totalItems++
                dropVar := "g_vLogGuiItem#" totalItems

                If (A_Index = 1)
                    this.AddGlobal("picture", "x+0 section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop
                else if !(rowDrops)
                    this.AddGlobal("picture", "xs ys+" dropSize + 1 " section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop of a new row
                else
                    this.AddGlobal("picture", "xp+" dropSize + 1 "  w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; add normal drop

                rowDrops++
            }
        }

        this.Tab("") ; Future controls are not part of any tab control.
        this.Margin(this.marginSize, this.marginSize) ; restore margin size
    }

    SavePos() {
        WinGetPos, guiLogX, guiLogY, guiLogW, guiLogH, % this.ahkid
        If !(guiLogX) or !(guiLogY)
            return
        If (guiLogX < 0) ; offscreen-left
            guiLogX := 0
        If (guiLogY < 0) ; offscreen-top
            guiLogY := 0
        If (guiLogX + guiLogW > A_ScreenWidth) ; offscreen-right
            guiLogX := A_ScreenWidth - guiLogW
        If (guiLogY + guiLogH > A_ScreenHeight) ; offscreen-bottom
            guiLogY := A_ScreenHeight - guiLogH

        SETTINGS_OBJ.guiLogX := guiLogX
        SETTINGS_OBJ.guiLogY := guiLogY
    }

    Close() {
        exitapp
    }
}

logGui_BtnClearDrops:
    LOG_GUI.ClearDrops()
return

logGui_BtnKill:
    LOG_GUI.AddKill()
return

logGui_BtnUndo:
    LOG_GUI.Undo()
return

logGui_BtnRedo:
    LOG_GUI.Redo()
return

logGui_BtnToggleDeath:
    LOG_GUI.ToggleDeath()
return

logGui_BtnToggleTrip:
    LOG_GUI.ToggleTrip()
return

logGui_BtnNewTrip:
    LOG_GUI.NewTrip()
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
    for a, b in ClassGuiLog.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
return

logGui_Close:
    ; call the class's method
    for a, b in ClassGuiLog.Instances 
		if (a = A_Gui+0)
			b["Events"]["_BtnClose"].Call()
return