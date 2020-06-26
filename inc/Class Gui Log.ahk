; save file in 'UTF-16 LE' format for symbols to display properly
class ClassGuiLog extends gui {
    Setup() {
        ; create window
        if (WinExist(this.ahkid)) {
            this.SavePos()
            this.Destroy()
        }
        this.__New("Log Gui")
        
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

        ; selected drops
        this.Add("edit", "x" this.marginSize " y" (this.marginSize * 2) + tabH " w" tabW  - this.marginSize + 3 " r1 section ReadOnly", "")

        ; btn clear drops
        _BTN_CLEAR_DROPS := this.Add("button", "x+" this.marginSize " ys-1  w23 glogGui_BtnClearDrops", "X")

        ; btn undo
        _BTN_UNDO := this.Add("button", "x+" this.marginSize + 123 " w" 23 " h23 glogGui_BtnUndo", "")
        GuiButtonIcon(_BTN_UNDO, PATH_GUI_ICONS "\undo_32.png", 1, 16, 0)

        ; btn redo
        _BTN_REDO := this.Add("button", "x+" this.marginSize " w" 23 " h23 glogGui_BtnRedo", "")
        GuiButtonIcon(_BTN_REDO, PATH_GUI_ICONS "\redo_32.png", 1, 16, 0)

        ; btn log menu
        _BTN_LOG_MENU := this.Add("button", "x+" this.marginSize " w" 23 " h23 glogGui_BtnLogMenu", "")
        GuiButtonIcon(_BTN_LOG_MENU, PATH_GUI_ICONS "\settings_hamburger_32.png", 1, 16, 0)

        ; drop log view
        this.Add("edit", "x" tabW + (this.marginSize * 2) + 27 " y" this.marginSize - 1 + 23 " w200 h" tabH - 22 " ReadOnly", "")

        ; btn add kill
        _BTN_KILL := this.Add("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 2 + 23 " w23 h" tabH - 20 " glogGui_BtnKill", "+")

        ; btn start / stop death
        this.Font("s11")
        _BTN_TOGGLE_DEATH := this.AddGlobal("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 4 " w23 h23 glogGui_BtnToggleDeath", "")
        this.Font("")

        ; btn start / stop trip
        _BTN_TOGGLE_TRIP := this.AddGlobal("button", "x+" this.marginSize " w" 98 " h23 glogGui_BtnToggleTrip", "")

        ; btn new trip
        _BTN_NEW_TRIP := this.Add("button", "x+" this.marginSize " w" 98 " h23 glogGui_BtnNewTrip", "  New Trip")
        SetButtonIcon(_BTN_NEW_TRIP, PATH_GUI_ICONS "\agility_icon.png", 1, 14)

        ; show
        this.ShowGui()
        this.CheckPos()
        this.Update()

        If (DB_SETTINGS.AutoShowStats)
            STATS_GUI.Setup()
    }

    Update() {
        this.SetText("edit2", DROP_LOG.GetFormattedLog())

        this.ClearDrops()

        ; buttons
        If (DROP_LOG.TripActive()) {
            this.Control("Enable", _BTN_TOGGLE_DEATH)
            this.Control("Enable", _BTN_KILL)
            this.Control("Enable", _BTN_CLEAR_DROPS)

            this.SetText(_BTN_TOGGLE_TRIP, "  End Trip") ; end trip
            SetButtonIcon(_BTN_TOGGLE_TRIP, PATH_GUI_ICONS "\stop_32.png", 1, 14)
        } else {
            this.Control("Disable", _BTN_TOGGLE_DEATH)
            this.Control("Disable", _BTN_KILL)
            this.Control("Disable", _BTN_CLEAR_DROPS)

            this.SetText(_BTN_TOGGLE_TRIP, "  Start Trip") ; start trip
            SetButtonIcon(_BTN_TOGGLE_TRIP, PATH_GUI_ICONS "\start_32.png", 1, 14)
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
        dropSize := DB_SETTINGS.logGuiDropSize
        maxRowDrops := DB_SETTINGS.logGuiMaxRowDrops ; after this amount of drops a new row is started

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
                    dropImg := PATH_ITEM_IMAGES "\" RUNELITE_API.GetItemId(drops[A_Index].name) ".png"

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
        WinGetPos(this.hwnd, guiLogX, guiLogY, guiLogW, guiLogH, true) 
        DB_SETTINGS.guiLogX := guiLogX
        DB_SETTINGS.guiLogY := guiLogY
    }

    CheckPos() {
        WinGetPos, guiLogX, guiLogY, guiLogW, guiLogH, % this.ahkid

        If (guiLogX < 0) ; offscreen-left
            DB_SETTINGS.guiLogX := 0
        If (guiLogY < 0) ; offscreen-top
            DB_SETTINGS.guiLogY := 0
        If (guiLogX + guiLogW > A_ScreenWidth) ; offscreen-right
            DB_SETTINGS.guiLogX := A_ScreenWidth - guiLogW
        If (guiLogY + guiLogH > A_ScreenHeight) ; offscreen-bottom
            DB_SETTINGS.guiLogY := A_ScreenHeight - guiLogH

        this.ShowGui()
    }

    ShowGui() {
        If !(DB_SETTINGS.guiLogX = "") and !(DB_SETTINGS.guiLogY = "")
            this.Show("x" DB_SETTINGS.guiLogX A_Space "y" DB_SETTINGS.guiLogY)
        else
            this.Show()
    }

    Close() {
        reload
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

logGui_Close:
    LOG_GUI.Close()
return

logGui_BtnLogMenu:
    logGuiDropSize := DB_SETTINGS.logGuiDropSize
    logGuiMaxRowDrops := DB_SETTINGS.logGuiMaxRowDrops
    tablesMergeBelowX := DB_SETTINGS.tablesMergeBelowX
    
    ; controls
    menu, logMenu, add
    menu, logMenu, DeleteAll
    menu, logMenu, add, Stats, LogMenu_Stats
    menu, logMenu, add
    menu, logMenu, add, Settings, menuHandler
    menu, logMenu, add, Gui - Item size`t%logGuiDropSize%, LogMenu_ItemSize
    menu, logMenu, add, Gui - Row length`t%logGuiMaxRowDrops%, LogMenu_RowLength
    menu, logMenu, add, Gui - Merge tables below`t%tablesMergeBelowX%, LogMenu_MergeTablesBelow
    menu, logMenu, add, Auto Show Stats, LogMenu_AutoShowStats
    menu, logMenu, add
    menu, logMenu, add, About, LogMenu_About

    ; properties
    menu, logMenu, Disable, Settings
    menu, logMenu, Icon, Stats, % PATH_GUI_ICONS "\osrs icons\Leagues_Tutor_icon.png", 1
    menu, logMenu, Icon, Settings, % PATH_GUI_ICONS "\osrs icons\Bounty_Hunter_-_task_config_icon.png", 1
    menu, logMenu, Icon, About, % PATH_GUI_ICONS "\osrs icons\Quest_start_icon.png", 1

    If (DB_SETTINGS.AutoShowStats)
        menu, logMenu, Check, Auto Show Stats

    ; show
    menu, logMenu, show
return

LogMenu_Stats:
    STATS_GUI.Setup()
return

LogMenu_AutoShowStats:
    DB_SETTINGS.AutoShowStats := !DB_SETTINGS.AutoShowStats

    If (DB_SETTINGS.AutoShowStats)
        STATS_GUI.Setup()
    else
        STATS_GUI.Close()
return

LogMenu_ItemSize:
    inputW := 100
    inputH := 130
    MouseGetPos, mouseX, mouseY
    InputBox, OutputVar, Item size, % "Between " MIN_DROP_SIZE " - " MAX_DROP_SIZE, , % inputW, % inputH, % mouseX - (inputW / 2) - 15, % mouseY - (inputH / 2), , , % DB_SETTINGS.logGuiDropSize
    If !(OutputVar) or (ErrorLevel) ; ErrorLevel = cancel
        return
    If (OutputVar < MIN_DROP_SIZE)
        OutputVar := MIN_DROP_SIZE
    If (OutputVar > MAX_DROP_SIZE)
        OutputVar := MAX_DROP_SIZE
    DB_SETTINGS.logGuiDropSize := OutputVar
    LOG_GUI.Setup()
return

LogMenu_RowLength:
    inputW := 100
    inputH := 130
    MouseGetPos, mouseX, mouseY
    InputBox, OutputVar, Item size, % "Between " MIN_ROW_LENGTH " - " MAX_ROW_LENGTH, , % inputW, % inputH, % mouseX - (inputW / 2) - 15, % mouseY - (inputH / 2), , , % DB_SETTINGS.logGuiMaxRowDrops
    If !(OutputVar) or (ErrorLevel) ; ErrorLevel = cancel
        return
    If (OutputVar < MIN_ROW_LENGTH)
        OutputVar := MIN_ROW_LENGTH
    If (OutputVar > MAX_ROW_LENGTH)
        OutputVar := MAX_ROW_LENGTH
    DB_SETTINGS.logGuiMaxRowDrops := OutputVar
    LOG_GUI.Setup()
return

LogMenu_MergeTablesBelow:
    inputW := 100
    inputH := 130
    MouseGetPos, mouseX, mouseY
    InputBox, OutputVar, Item size, % "Between " MIN_ROW_LENGTH " - " MAX_ROW_LENGTH, , % inputW, % inputH, % mouseX - (inputW / 2) - 15, % mouseY - (inputH / 2), , , % DB_SETTINGS.tablesMergeBelowX
    If !(OutputVar) or (ErrorLevel) ; ErrorLevel = cancel
        return
    If (OutputVar < MIN_ROW_LENGTH)
        OutputVar := MIN_ROW_LENGTH
    If (OutputVar > MAX_ROW_LENGTH)
        OutputVar := MAX_ROW_LENGTH
    DB_SETTINGS.tablesMergeBelowX := OutputVar
    DROP_TABLE._TablesMergeBelowX()
    LOG_GUI.Setup()
return

LogMenu_About:
    GuiAbout()
return