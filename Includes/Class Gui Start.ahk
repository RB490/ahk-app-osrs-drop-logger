class ClassGuiStart extends gui {
    Get() {
        ; events
        this.Events["_HotkeyEnter"] := this.BtnAdd.Bind(this)

        ; properties
        this.marginSize := 10
        totalWidth := 200

        ; controls
        this.Add("edit", "w" totalWidth + 10 - this.marginSize " section", "", this.SearchBoxHandler.Bind(this))
        
        this.Add("listbox", "x" this.marginSize " w" totalWidth " r10", , this.MobListBoxHandler.Bind(this))
        this._btnLog := this.Add("button", "w" totalWidth " r3", "Log", this.BtnLog.Bind(this))

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, ClassGuiStart_HotkeyEnter
        Hotkey, IfWinActive

        ; show
        this.Show()
        this.Update()
    }

    Update() {
        ; check user input
        searchString := this.GetText("Edit1")

        ; build display var
        for count, mob in MOB_DB.GetList()
            If InStr(mob, searchString)
                output .= mob "|"
        output := RTrim(output, "|")

        ; update MobListBox
        this.Control(,"ListBox1", "|") ; clear content
        this.Control(,"ListBox1", output) ; load content
        this.Control("Choose","ListBox1", SCRIPT_SETTINGS.previousMob)

        ; buttons
        If !SCRIPT_SETTINGS.previousMob
            this.Control("Disable", this._btnLog)

        this._LoadMobImage()
    }

    MobListBoxHandler() {
        SCRIPT_SETTINGS.previousMob := this.GuiControlGet("", "ListBox1")
        this.Control("Enable", this._btnLog)
    }

    _LoadMobImage() {
        If !SCRIPT_SETTINGS.previousMob {
            this.SetText(this._btnLog, "Log                     ")
            GuiButtonIcon(this._btnLog, A_ScriptDir "\Assets\Images\Unavailable.png", 1, "s44 a0 l50 r0")
            return  
        }
        
        ; DownloadMobImage(SCRIPT_SETTINGS.previousMob) ; todo

        this.SetText(this._btnLog, "       Log")
        path := DIR_MOB_IMAGES "\" SCRIPT_SETTINGS.previousMob ".png"
        SetButtonIcon(this._btnLog, path, 1, 44) ; r2 = 30, r3 = 44
    }

    SearchBoxHandler() {
        this.Update()
    }

    SearchBoxReset() {
        this.SetText("edit1")
        this.Update()
    }

    BtnLog() {
        this.Disable()
        selectedLogFile := DB_SETTINGS.selectedLogFile
        SplitPath, selectedLogFile, OutFileName, selectedLogFileDir, OutExtension, OutNameNoExt, OutDrive
        FileSelectFile, SelectedFile, 11, % manageGui.GetText("Edit1"), Select drop log, Json (*.json), %selectedLogFileDir%
        If !SelectedFile {
            Msg("Info", A_ThisFunc, "Can't log without a log file")
            this.Enable()
            return false
        }
        SplitPath, SelectedFile , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
        file := OutDir "\" OutNameNoExt ".json"

        success := DROP_LOG.Get(file)
        If !success
            return
        DB_SETTINGS.selectedLogFile := file
        this.Enable()
        this.Hide()
        success := DROP_TABLE.Get(SCRIPT_SETTINGS.previousMob)
        If !success
            Msg("Error", A_ThisFunc, "Failed to retrieve drop table for verified, saved mob")
        LOG_GUI.Get()
    }

    ContextMenu() {
        StartMenu_Show()
    }

    Close() {
        exitapp
    }
}

StartMenu_Show() {
    If !SCRIPT_SETTINGS.previousMob or !A_EventInfo ; A_EventInfo = ListBox Target
        return

    mobMenuMob := SCRIPT_SETTINGS.previousMob

    menu, mobMenu, add
    menu, mobMenu, DeleteAll
    menu, mobMenu, add, Remove %mobMenuMob%, StartMenu_RemoveMob
    menu, mobMenu, show
}

StartMenu_RemoveMob() {
    SCRIPT_SETTINGS.previousMobs.Delete(SCRIPT_SETTINGS.previousMob)
    SCRIPT_SETTINGS.previousMob := ""
    Start_GUI.Update()
}

ClassGuiStart_HotkeyEnter() {
    ; call the class's method
    for a, b in ClassGuiStart.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
}