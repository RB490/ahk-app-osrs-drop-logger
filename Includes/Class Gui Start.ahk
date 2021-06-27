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

    Update(basicUpdate := false) {
        If !basicUpdate {
            ; check user input
            searchString := this.GetText("Edit1")

            ; build display var
            for id, mob in MOB_DB.GetList()
                If InStr(mob, searchString)
                    output .= mob "|"
            output := RTrim(output, "|")

            ; update MobListBox
            this.Control(,"ListBox1", "|") ; clear content
            this.Control(,"ListBox1", output) ; load content
            this.Control("Choose","ListBox1", SCRIPT_SETTINGS.previousMob)
        }

        ; buttons
        If !SCRIPT_SETTINGS.previousMob
            this.Control("Disable", this._btnLog)
        else
            this.Control("Enable", this._btnLog)

        this._LoadMobImage()
    }

    MobListBoxHandler() {
        SCRIPT_SETTINGS.previousMob := this.GuiControlGet("", "ListBox1")
        this.Update("basicUpdate")
    }

    _LoadMobImage() {
        If !SCRIPT_SETTINGS.previousMob {
            this.SetText(this._btnLog, "Log                     ")
            GuiButtonIcon(this._btnLog, A_ScriptDir "\Assets\Images\Unavailable.png", 1, "s44 a0 l50 r0")
            return  
        }
        
        previousMobId := MOB_DB.GetId(SCRIPT_SETTINGS.previousMob)
        DownloadMobImage(SCRIPT_SETTINGS.previousMob, previousMobId)

        this.SetText(this._btnLog, "       Log")
        path := DIR_MOB_IMAGES "\" previousMobId ".png"
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

        ; prompt user to select a drop log filepath
        previousLogFile := SCRIPT_SETTINGS.previousLogFile
        SplitPath, previousLogFile, OutFileName, previousLogFileDir, OutExtension, OutNameNoExt, OutDrive
        FileSelectFile, previousFile, 11, % manageGui.GetText("Edit1"), Select drop log, Json (*.json), %previousLogFileDir%
        If !previousFile {
            Msg("Info", A_ThisFunc, "Can't log without a log file")
            this.Enable()
            return false
        }
        SplitPath, previousFile , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
        file := OutDir "\" OutNameNoExt ".json"
        SCRIPT_SETTINGS.previousLogFile := file ; save file location

        ; attempt to load the selected drop log file
        If !DROP_LOG.Get(file)
            return

        ; verify we have a drop table for selected mob
        this.Enable()
        this.Hide()
        If !DROP_TABLE.Get(SCRIPT_SETTINGS.previousMob)
            Msg("Error", A_ThisFunc, "Failed to retrieve drop table for verified, saved mob")

        ; show the drop log gui
        LOG_GUI.Get()
    }

    ContextMenu() {
    }

    Close() {
        exitapp
    }
}

ClassGuiStart_HotkeyEnter() {
    ; call the class's method
    for a, b in ClassGuiStart.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
}