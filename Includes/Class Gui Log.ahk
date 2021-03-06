; save file in 'UTF-16 LE' format for symbols to display properly
class ClassGuiLog extends gui {

    Get() {
        ; retrieve variables
        this.dropSize := SCRIPT_SETTINGS.guiLog_DropSize
        this.maxRowDrops := SCRIPT_SETTINGS.guiLog_MaxRowDrops ; after this amount of drops a new row is started
        this.dropsImageDir := GetGuiLogDropsImageType()

        ; create window
        if WinExist(this.ahkid) {
            this.SavePos()
            this.Destroy()
        }
        this.__New(APP_NAME)
        
        ; properties
        this.marginSize := 5

        ; variables
        btnW := 100

        ; controls
        ; this.Color("F0F0F0", "F0F0F0")
        this.Add("tab3", "x" this.marginSize " ", "")
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
        this._btnClearDrops := this.Add("button", "x+" this.marginSize " ys-1  w23", "X", this.ClearDrops.Bind(this))

        ; btn undo
        this._btnUndo := this.Add("button", "x+" this.marginSize + 123 " w" 23 " h23", "", this.Undo.Bind(this))
        GuiButtonIcon(this._btnUndo, DIR_GUI_ICONS "\undo_32.png", 1, "s16")

        ; btn redo
        this._btnRedo := this.Add("button", "x+" this.marginSize " w" 23 " h23", "", this.Redo.Bind(this))
        GuiButtonIcon(this._btnRedo, DIR_GUI_ICONS "\redo_32.png", 1, "s16")

        ; btn log menu
        this._btnShowMenu := this.Add("button", "x+" this.marginSize " w" 23 " h23", "", this.ShowMenu.Bind(this))
        GuiButtonIcon(this._btnShowMenu, DIR_GUI_ICONS "\settings_hamburger_32.png", 1, "s16")

        ; drop log view
        this.Add("edit", "x" tabW + (this.marginSize * 2) + 27 " y" this.marginSize - 1 + 23 " w200 h" tabH - 22 " ReadOnly", "")

        ; btn add kill
        this._btnAddKill := this.Add("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 2 + 23 " w23 h" tabH - 20 "", "+", this.AddKill.Bind(this))

        ; btn start / stop death
        this.Font("s11")
        this._btnToggleDeath := this.Add("button", "x" tabW + this.marginSize + 3 " y" this.marginSize - 4 " w23 h23", "", this.ToggleDeath.Bind(this))
        this.Font("")

        ; btn start / stop trip
        this._btnToggleTrip := this.Add("button", "x+" this.marginSize " w" 98 " h23", "",this.ToggleTrip.Bind(this))

        ; btn new trip
        this._btnNewTrip := this.Add("button", "x+" this.marginSize " w" 98 " h23", "New Trip   ", this.NewTrip.Bind(this))
        GuiButtonIcon(this._btnNewTrip, DIR_GUI_ICONS "\agility_icon_23.png", 1, "s14 a0 l10 r0")

        ; hotkey
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, ClassGuiLog_HotkeyEnter
        Hotkey, IfWinActive

        ; show
        this.ShowGui()
        this.CheckPos()
        
        If SCRIPT_SETTINGS.guiLog_AutoShowStats
            GUI_STATS.Get()
        this.Update()
    }

    Update() {
        this.SetText("edit2", DROP_LOG.GetFormattedLog())

        ; drops
        loop % SELECTED_DROPS.length()
            drops .= SELECTED_DROPS[A_Index].quantity " x " SELECTED_DROPS[A_Index].name ", "
        drops := RTrim(drops, ", ")
        this.SetText("edit1", drops)

        ; buttons
        If DROP_LOG.TripActive() {
            this.Control("Enable", this._btnToggleDeath)
            this.Control("Enable", this._btnAddKill)
            this.Control("Enable", this._btnClearDrops)

            this.SetText(this._btnToggleTrip, "End Trip   ") ; end trip
            GuiButtonIcon(this._btnToggleTrip, DIR_GUI_ICONS "\stop_32.png", 1, "s14 a0 l10 r0")
        } else {
            this.Control("Disable", this._btnToggleDeath)
            this.Control("Disable", this._btnAddKill)
            this.Control("Disable", this._btnClearDrops)

            this.SetText(this._btnToggleTrip, "Start Trip   ") ; start trip
            GuiButtonIcon(this._btnToggleTrip, DIR_GUI_ICONS "\start_32.png", 1, "s14 a0 l10 r0")
        }

        If DROP_LOG.DeathActive() {
            this.SetText(this._btnToggleDeath, "♥") ; end death
            this.Control("Disable", this._btnAddKill)
            this.Control("Disable", this._btnClearDrops)
            this.Control("Disable", this._btnNewTrip)
            this.Control("Disable", this._btnToggleTrip)
        } else {
            this.SetText(this._btnToggleDeath, "☠") ; start death
            this.Control("Enable", this._btnNewTrip)
            this.Control("Enable", this._btnToggleTrip)
        }

        If DROP_LOG.redoActions.length()
            this.Control("Enable", this._btnRedo)
        else
            this.Control("Disable", this._btnRedo)

        If DROP_LOG.undoActions.length()
            this.Control("Enable", this._btnUndo)
        else
            this.Control("Disable", this._btnUndo)

        If SELECTED_DROPS.length() {
            this.Control("Enable", this._btnAddKill)
            this.Control("Enable", this._btnClearDrops)
        }
        else {
            this.Control("Disable", this._btnAddKill)
            this.Control("Disable", this._btnClearDrops)
        }

        If DEBUG_MODE
            SetTimer, updateStats, -500 ; some delay so the stats gui doesnt get updated too much and starts flickering. not redrawing the listviews didnt help with that
        else
            SetTimer, updateStats, -10000 ; some delay so the stats gui doesnt get updated too much and starts flickering. not redrawing the listviews didnt help with that
    }

    ShowMenu() {
        Gosub MiscMenu_Show
    }

    ClearDrops() {
        SELECTED_DROPS := {}
        this.SetText("Edit1")
        this.Update()
    }

    AddKill() {
        DROP_LOG.AddKill(SELECTED_DROPS)
        this.ClearDrops()
        this.Update()
    }

    Undo() {
        DROP_LOG.Undo()
        this.ClearDrops()
        this.Update()
    }

    Redo() {
        DROP_LOG.Redo()
        this.ClearDrops()
        this.Update()
    }

    StartTrip() {
        DROP_LOG.StartTrip()
        this.ClearDrops()
        this.Update()
    }

    EndTrip() {
        DROP_LOG.EndTrip()
        this.ClearDrops()
        this.Update()
    }

    ToggleTrip() {
        DROP_LOG.ToggleTrip()
        this.ClearDrops()
        this.Update()
    }

    ToggleDeath() {
        DROP_LOG.ToggleDeath()
        this.ClearDrops()
        this.Update()
    }

    NewTrip() {
        DROP_LOG.NewTrip()
        this.ClearDrops()
        this.Update()
    }

    _LoadDrops() {
        ; set required variables
        this.Margin(0, 0)

        ; load the fucking drops
        dropsList := DROP_TABLE.Get(SCRIPT_SETTINGS.previousMob)
        dropsList["RDT"] := RDT_Get()

        ; start with the main category
        this._LoadDropsInCategory("Main", dropsList["Main"])
        this._LoadDropsInCategory("RDT", dropsList["RDT"])

        ; continue with the remaining categories
        for category in dropsList {
            If (category = "Main") or (category = "RDT")
                Continue
            this._LoadDropsInCategory(category, dropsList[category])
        }

        this.Tab("") ; Future controls are not part of any tab control.
        this.Margin(this.marginSize, this.marginSize) ; restore margin size
    }

    _LoadDropsInCategory(categoryName, categoryObj) {
        ; create category tab
        this.Control(,"SysTabControl321", categoryName)
        this.Tab(categoryName) ; select tab
        
        ; add category drops
        for index, drop in categoryObj {
            ; if current row meets the maximum length, start a new row
            If (rowDrops = this.maxRowDrops)
                rowDrops := 0

            ; set drop variables
            dropImg := this.dropsImageDir "\" drop.id ".png"
            dropVar := categoryName A_Index "#" str2hex(json.dump(drop))
            dropSize := this.dropSize

            If (index = 1) {
                ; msgbox first drop of this category
                ;  first drop of this category. the position of the other images will be based off of this
                this.AddStatic("picture", "x+0 section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop
            }
            else if !rowDrops {
                ; msgbox first drop of a new row
                ; first drop of a new row
                this.AddStatic("picture", "xs ys+" dropSize + 1 " section w" dropSize " h" dropSize " v" dropVar " border", dropImg)
            }
            else {
                ; msgbox 'normal' drop
                ; 'normal' drop. added after either one of the above two ^
                this.AddStatic("picture", "xp+" dropSize + 1 "  w" dropSize " h" dropSize " v" dropVar " border", dropImg)
            }

            rowDrops++ ; keep track of drops in current row     
        }
    }

    SavePos() {
        WinGetPos(this.hwnd, guiLog_X, guiLog_Y, guiLog_W, guiLog_H, true) 
        If !guiLog_W and !guiLog_H
            return
        SCRIPT_SETTINGS.guiLog_X := guiLog_X
        SCRIPT_SETTINGS.guiLog_Y := guiLog_Y
    }

    CheckPos() {
        WinGetPos, guiLog_X, guiLog_Y, guiLog_W, guiLog_H, % this.ahkid

        If (guiLog_X < 0) ; offscreen-left
            SCRIPT_SETTINGS.guiLog_X := 0
        If (guiLog_Y < 0) ; offscreen-top
            SCRIPT_SETTINGS.guiLog_Y := 0
        If (guiLog_X + guiLog_W > A_ScreenWidth) ; offscreen-right
            SCRIPT_SETTINGS.guiLog_X := A_ScreenWidth - guiLog_W
        If (guiLog_Y + guiLog_H > A_ScreenHeight) ; offscreen-bottom
            SCRIPT_SETTINGS.guiLog_Y := A_ScreenHeight - guiLog_H

        this.ShowGui()
    }

    ShowGui() {
        If IsInteger(SCRIPT_SETTINGS.guiLog_X) and IsInteger(SCRIPT_SETTINGS.guiLog_Y)
            this.Show("x" SCRIPT_SETTINGS.guiLog_X A_Space "y" SCRIPT_SETTINGS.guiLog_Y)
        else
            this.Show()
    }

    Close() {
        GUI_LOG.Hide()
        GUI_STATS.Hide()
        GUI_START.Show()
        SaveSettings()
    }
}

ClassGuiLog_HotkeyEnter() {
    GUI_LOG.AddKill()
}

MiscMenu_Show:
    logGuiDropSize := SCRIPT_SETTINGS.guiLog_DropSize
    logGuiMaxRowDrops := SCRIPT_SETTINGS.guiLog_MaxRowDrops
    logGuiMaxTableSize := SCRIPT_SETTINGS.guiLog_MaxTableSize
    logGuiItemImageType := SCRIPT_SETTINGS.guiLog_ItemImageType
    MiscMenu_Mob := SCRIPT_SETTINGS.previousMob
    MiscMenu_LogFile := SCRIPT_SETTINGS.previousLogFile
    
    ; controls
    menu, MiscMenu, add
    menu, MiscMenu, DeleteAll
    menu, MiscMenu, add, Mob `t%MiscMenu_Mob%, MiscMenu_Mob
    menu, MiscMenu, add, File `t%MiscMenu_LogFile%, MiscMenu_LogFile
    menu, MiscMenu, add
    menu, MiscMenu, add, Stats, MiscMenu_Stats
    menu, MiscMenu, add, Settings, MiscMenu_Settings
    menu, MiscMenu, add, About, MiscMenu_About

    ; properties
    menu, MiscMenu, Icon, Stats, % DIR_GUI_ICONS "\osrs_icons\Leagues_Tutor_icon.png", 1
    menu, MiscMenu, Icon, Settings, % DIR_GUI_ICONS "\osrs_icons\Bounty_Hunter_-_task_config_icon.png", 1
    menu, MiscMenu, Icon, About, % DIR_GUI_ICONS "\osrs_icons\Quest_start_icon.png", 1

    menu, MiscMenu, Icon, Mob `t%MiscMenu_Mob%, % DIR_MOB_IMAGES "\" OSRS.GetMobID(MiscMenu_Mob) ".png", 1, 20

    ; show
    menu, MiscMenu, show
return

MiscMenu_LogFile:
    DROP_LOG.Save()
    
    ; slight workaround because (my) windows 10 doesnt open json files for some reason
    Run % "explorer.exe /select, """ SCRIPT_SETTINGS.previousLogFile """"
return

MiscMenu_Mob:
    run, % OSRS.GetMobUrl(SCRIPT_SETTINGS.previousMob)
return

MiscMenu_Stats:
    GUI_STATS.Get()
return

MiscMenu_Settings:
    GUI_LOG.Disable()
    savedSettings := GUI_SETTINGS.Get()
    GUI_LOG.Enable()
    If !savedSettings {
        GUI_LOG.Show() ; bring to front
        return
    }
    GUI_LOG.Get() ; redraw
return

MiscMenu_About:
    GUI_ABOUT.Get()
return