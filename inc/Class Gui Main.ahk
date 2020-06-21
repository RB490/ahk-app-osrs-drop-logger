class ClassGuiMain extends gui {
    Setup() {
        ; events
        this.Events["_BtnAdd"] := this.BtnAdd.Bind(this)
        this.Events["_BtnLog"] := this.BtnLog.Bind(this)
        this.Events["_HotkeyEnter"] := this.BtnAdd.Bind(this)
        this.Events["_MobListBoxHandler"] := this.MobListBoxHandler.Bind(this)
        this.Events["_SearchBoxHandler"] := this.SearchBoxHandler.Bind(this)

        ; properties
        this.marginSize := 10
        totalWidth := 200
        this.Options("+LabelmainGui_")

        ; controls
        ; this.Add("text", "", "Search")
        this.Add("edit", "w" totalWidth - 45 - this.marginSize " section gmainGui_SearchBoxHandler", "")
        this.Add("button", "x+5 ys-1 w50 gmainGui_BtnHandler", "Add")
        this.Add("listbox", "x" this.marginSize " w" totalWidth " r10 gmainGui_MobListBoxHandler", "")
        this.Add("button", "w" totalWidth " gmainGui_BtnHandler", "Log")

        this.Add("picture", "w200 h200 border", "")

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, mainGui_HotkeyEnter
        Hotkey, IfWinActive

        ; show
        this.Show()
        this.Update()
        this._LoadMobImage()
        WinWaitClose, % this.ahkid
    }

    Update() {
        this.SetDefault() ; for guicontrol
        
        ; check user input
        input := this.GetText("Edit1")

        ; build display var
        for mob, v in SETTINGS_OBJ.mobs
            If (InStr(mob, input))
                output .= mob "|"
        output := RTrim(output, "|")

        ; update MobListBox
        GuiControl,, ListBox1 , |
        GuiControl,, ListBox1 , % output
        GuiControl, Choose, ListBox1, % SETTINGS_OBJ.selectedMob
    }

    MobListBoxHandler() {
        SETTINGS_OBJ.selectedMob := this.GuiControlGet("", "ListBox1")
        this.ControlFocus("edit1") ; prevent ctrl+s from changing current mob

        this._LoadMobImage()
    }

    _LoadMobImage() {
        If !(SETTINGS_OBJ.selectedMob)
            return  
        
        path := PATH_MOB_IMAGES "\" SETTINGS_OBJ.selectedMob ".png"
        If !(FileExist(path)) {
            url := WIKI_API.GetMobUrl(SETTINGS_OBJ.selectedMob)
            DownloadToFile(url, path)
        }

        this.SetDefault() ; for guicontrol
        GuiControl,,Static1, % path
    }

    SearchBoxHandler() {
        this.update()
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
        If (SETTINGS_OBJ.mobs.HasKey(input)) {
            SETTINGS_OBJ.selectedMob := input
            this.SearchBoxReset()
            return
        }

        ; check if input is a mob with drop tables
        isValidMob := DROP_TABLE.Get(input)
        If !(isValidMob) {
            msgbox, 4160, , % A_ThisFunc ": Could not find drop table for '" input "'!"
            this.SearchBoxReset()
            return
        }

        ; save mob
        If !(IsObject(SETTINGS_OBJ.mobs))
            SETTINGS_OBJ.mobs := {}
        SETTINGS_OBJ.mobs[input] := ""

        ; apply new mob
        SETTINGS_OBJ.selectedMob := input
        this.SearchBoxReset()
    }

    BtnLog() {
        result := DROP_LOG.Load()
        If !(result)
            return
        this.Hide()
        DROP_TABLE.Get(SETTINGS_OBJ.selectedMob)
        LOG_GUI.Setup()
    }
}

mainGui_ContextMenu:
    If !(SETTINGS_OBJ.selectedMob) or !(A_EventInfo) ; A_EventInfo = ListBox Target
        return
    
    mobMenuMob := SETTINGS_OBJ.selectedMob

    menu, mobMenu, add
    menu, mobMenu, DeleteAll
    menu, mobMenu, add, Remove %mobMenuMob%, mobMenu_removeMob
    menu, mobMenu, show
return

mobMenu_removeMob:
    SETTINGS_OBJ.mobs.Delete(SETTINGS_OBJ.selectedMob)
    SETTINGS_OBJ.selectedMob := ""
    mainGui.Update()
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

mainGui_BtnHandler:
    ; get active button text without spaces
    ControlGetFocus, OutputControl, A
    ControlGetText, OutputControlText, % OutputControl, A
    OutputControlText := StrReplace(OutputControlText, A_Space)

    ; call the class's method
    for a, b in ClassGuiMain.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
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