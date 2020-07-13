class ClassGuiMain extends gui {
    Get() {
        ; events
        this.Events["_HotkeyEnter"] := this.BtnAdd.Bind(this)

        ; properties
        this.marginSize := 10
        totalWidth := 200

        ; controls
        this.Add("edit", "w" totalWidth - 45 - this.marginSize " section", "", this.SearchBoxHandler.Bind(this))
        this.Add("button", "x+5 ys-1 w50", "Add", this.BtnAdd.Bind(this))
        
        this.Add("listbox", "x" this.marginSize " w" totalWidth " r10", , this.MobListBoxHandler.Bind(this))
        this._btnLog := this.Add("button", "w" totalWidth " r3", "Log", this.BtnLog.Bind(this))

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, ClassGuiMain_HotkeyEnter
        Hotkey, IfWinActive

        ; show
        this.Show()
        this.Update()
    }

    Update() {
        ; check user input
        searchString := this.GetText("Edit1")

        ; build display var
        for mob in DB_SETTINGS.selectedMobs
            If InStr(mob, searchString)
                output .= mob "|"
        output := RTrim(output, "|")

        ; update MobListBox
        this.Control(,"ListBox1", "|") ; clear content
        this.Control(,"ListBox1", output) ; load content
        this.Control("Choose","ListBox1", DB_SETTINGS.selectedMob)

        ; ------------------------------------------------

        ; buttons
        If DB_SETTINGS.selectedMob
            this.Control("Enable", this._btnLog)
        else
            this.Control("Disable", this._btnLog)

        this._LoadMobImage()
    }

    MobListBoxHandler() {
        DB_SETTINGS.selectedMob := this.GuiControlGet("", "ListBox1")
        this.ControlFocus("edit1") ; prevent ctrl+s from changing current mob

        this.Update()
    }

    _LoadMobImage() {
        If !DB_SETTINGS.selectedMob {
            this.SetText(this._btnLog, "Log                     ")
            GuiButtonIcon(this._btnLog, A_ScriptDir "\res\img\Nothing.png", 1, "s44 a0 l50 r0")
            return  
        }
        
        DownloadMobImage(DB_SETTINGS.selectedMob)

        this.SetText(this._btnLog, "       Log")
        SetButtonIcon(this._btnLog, path, 1, 44) ; r2 = 30, r3 = 44
    }

    SearchBoxHandler() {
        this.Update()
    }

    SearchBoxReset() {
        this.SetText("edit1")
        this.Update()
    }

    BtnAdd() {
        ; receive input
        input := this.GetText("edit1")
        If !input
            return
        StringUpper, input, input, T

        ; check if mob already exists
        If DB_SETTINGS.selectedMobs.HasKey(input) {
            DB_SETTINGS.selectedMob := input
            this.SearchBoxReset()
            return
        }

        ; check if input is a mob with drop tables
        isValidMob := DROP_TABLE.Get(input)
        If !isValidMob {
            this.SearchBoxReset()
            return
        }

        ; save mob
        If !IsObject(DB_SETTINGS.selectedMobs)
            DB_SETTINGS.selectedMobs := {}
        DB_SETTINGS.selectedMobs[input] := ""

        ; apply new mob
        DB_SETTINGS.selectedMob := input
        this.SearchBoxReset()
    }

    BtnLog() {
        this.Disable()
        selectedLogFile := DB_SETTINGS.selectedLogFile
        SplitPath, selectedLogFile, OutFileName, selectedLogFileDir, OutExtension, OutNameNoExt, OutDrive
        FileSelectFile, SelectedFile, 11, % manageGui.GetText("Edit1"), Select drop log, Json (*.json), %selectedLogFileDir%
        If !SelectedFile {
            ; msgbox, 4160, , % A_ThisFunc ": Can't log without a log file"
            this.Enable()
            return false
        }
        SplitPath, SelectedFile , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
        file := OutDir "\" OutNameNoExt ".json"

        result := DROP_LOG.Get(file)
        If !result
            return
        DB_SETTINGS.selectedLogFile := file
        this.Enable()
        this.Hide()
        result := DROP_TABLE.Get(DB_SETTINGS.selectedMob)
        If (result = false) {
            msgbox, 4160, , % A_ThisFunc ": Check: " PROJECT_WEBSITE ; failed to retrieve drop table for verified, saved mob
            return
        }
        LOG_GUI.Get()
    }

    ContextMenu() {
        MainMenu_Show()
    }

    Close() {
        exitapp
    }
}

MainMenu_Show() {
    If !DB_SETTINGS.selectedMob or !A_EventInfo ; A_EventInfo = ListBox Target
        return

    mobMenuMob := DB_SETTINGS.selectedMob

    menu, mobMenu, add
    menu, mobMenu, DeleteAll
    menu, mobMenu, add, Remove %mobMenuMob%, MainMenu_RemoveMob
    menu, mobMenu, show
}

MainMenu_RemoveMob() {
    DB_SETTINGS.selectedMobs.Delete(DB_SETTINGS.selectedMob)
    DB_SETTINGS.selectedMob := ""
    MAIN_GUI.Update()
}

ClassGuiMain_HotkeyEnter() {
    ; call the class's method
    for a, b in ClassGuiMain.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
}