class ClassGuiMain extends gui {
    Setup() {
        ; events
        this.Events["_BtnAdd"] := this.BtnAdd.Bind(this)
        this.Events["_BtnLog"] := this.BtnLog.Bind(this)
        this.Events["_BtnClose"] := this.Close.Bind(this)
        this.Events["_HotkeyEnter"] := this.BtnAdd.Bind(this)
        this.Events["_MobListBoxHandler"] := this.MobListBoxHandler.Bind(this)
        this.Events["_SearchBoxHandler"] := this.SearchBoxHandler.Bind(this)

        ; properties
        this.marginSize := 10
        totalWidth := 200
        this.Options("+LabelmainGui_")

        ; controls
        this.Add("edit", "w" totalWidth - 45 - this.marginSize " section gmainGui_SearchBoxHandler", "")
        this.Add("button", "x+5 ys-1 w50 gmainGui_BtnAdd", "Add")
        this.Add("listbox", "x" this.marginSize " w" totalWidth " r10 gmainGui_MobListBoxHandler", "")
        _MAIN_GUI_BTN_LOG := this.AddGlobal("button", "w" totalWidth " gmainGui_BtnLog r3", "Log")

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, mainGui_HotkeyEnter
        Hotkey, IfWinActive

        ; show
        this.Show()
        this.Update()
    }

    Update() {
        this.SetDefault() ; for guicontrol
        
        ; ----------------------search--------------------

        ; check user input
        input := this.GetText("Edit1")

        ; build display var
        for mob, v in DB_SETTINGS.mobs
            If (InStr(mob, input))
                output .= mob "|"
        output := RTrim(output, "|")

        ; update MobListBox
        GuiControl,, ListBox1 , |
        GuiControl,, ListBox1 , % output
        GuiControl, Choose, ListBox1, % DB_SETTINGS.selectedMob

        ; ------------------------------------------------

        ; buttons
        If (DB_SETTINGS.selectedMob)
            this.Control("Enable", _MAIN_GUI_BTN_LOG)
        else
            this.Control("Disable", _MAIN_GUI_BTN_LOG)

        this._LoadMobImage()
    }

    MobListBoxHandler() {
        DB_SETTINGS.selectedMob := this.GuiControlGet("", "ListBox1")
        this.ControlFocus("edit1") ; prevent ctrl+s from changing current mob

        this.Update()
    }

    _LoadMobImage() {
        If !(DB_SETTINGS.selectedMob) {
            this.SetText(_MAIN_GUI_BTN_LOG, "Log                     ")
            GuiButtonIcon(_MAIN_GUI_BTN_LOG, A_ScriptDir "\res\img\Nothing.png", 1, "s44 a0 l50 r0")
            return  
        }
        
        path := DIR_MOB_IMAGES "\" DB_SETTINGS.selectedMob ".png"
        If !(FileExist(path)) {
            url := WIKI_API.GetMobImageDetailUrl(DB_SETTINGS.selectedMob)
            DownloadToFile(url, path)
        }

        this.SetDefault() ; for guicontrol
        this.SetText(_MAIN_GUI_BTN_LOG, "       Log")
        SetButtonIcon(_MAIN_GUI_BTN_LOG, path, 1, 44) ; r2 = 30, r3 = 44
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
        If !(input)
            return
        StringUpper, input, input, T

        ; check if mob already exists
        If (DB_SETTINGS.mobs.HasKey(input)) {
            DB_SETTINGS.selectedMob := input
            this.SearchBoxReset()
            return
        }

        ; check if input is a mob with drop tables
        isValidMob := DROP_TABLE.Get(input)
        If !(isValidMob) {
            this.SearchBoxReset()
            return
        }

        ; save mob
        If !(IsObject(DB_SETTINGS.mobs))
            DB_SETTINGS.mobs := {}
        DB_SETTINGS.mobs[input] := ""

        ; apply new mob
        DB_SETTINGS.selectedMob := input
        this.SearchBoxReset()
    }

    BtnLog() {
        this.Disable()
        selectedLogFile := DB_SETTINGS.selectedLogFile
        SplitPath, selectedLogFile, OutFileName, selectedLogFileDir, OutExtension, OutNameNoExt, OutDrive
        FileSelectFile, SelectedFile, 11, % manageGui.GetText("Edit1"), Select drop log, Json (*.json), %selectedLogFileDir%
        If !(SelectedFile) {
            ; msgbox, 4160, , % A_ThisFunc ": Can't log without a log file"
            this.Enable()
            return false
        }
        SplitPath, SelectedFile , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
        file := OutDir "\" OutNameNoExt ".json"

        result := DROP_LOG.Load(file)
        If !(result)
            return
        DB_SETTINGS.selectedLogFile := file
        this.Enable()
        this.Hide()
        result := DROP_TABLE.Get(DB_SETTINGS.selectedMob)
        If (result = false) {
            msgbox, 4160, , % A_ThisFunc ": Check: " PROJECT_WEBSITE ; failed to retrieve drop table for verified, saved mob
            return
        }
        LOG_GUI.Setup()
    }

    Close() {
        exitapp
    }
}

mainGui_ContextMenu:
    If !(DB_SETTINGS.selectedMob) or !(A_EventInfo) ; A_EventInfo = ListBox Target
        return
    
    mobMenuMob := DB_SETTINGS.selectedMob

    menu, mobMenu, add
    menu, mobMenu, DeleteAll
    menu, mobMenu, add, Remove %mobMenuMob%, mobMenu_removeMob
    menu, mobMenu, show
return

mobMenu_removeMob:
    DB_SETTINGS.mobs.Delete(DB_SETTINGS.selectedMob)
    DB_SETTINGS.selectedMob := ""
    MAIN_GUI.Update()
return

mainGui_MobListBoxHandler:
	; call the class's method
    for a, b in ClassGuiMain.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_MobListBoxHandler"].Call()
return

mainGui_SearchBoxHandler:
	; call the class's method
    for a, b in ClassGuiMain.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_SearchBoxHandler"].Call()
return

mainGui_BtnAdd:
    MAIN_GUI.BtnAdd()
return

mainGui_BtnLog:
    MAIN_GUI.BtnLog()
return

mainGui_HotkeyEnter:
	; call the class's method
    for a, b in ClassGuiMain.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
return

mainGui_Close:
    ; call the class's method
    for a, b in ClassGuiMain.Instances 
		if (a = A_Gui+0)
			b["Events"]["_BtnClose"].Call()
return