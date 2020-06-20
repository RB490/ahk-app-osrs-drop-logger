class class_gui_mob extends gui {
    Setup() {
        ; events
        this.Events["_BtnAdd"] := this.BtnAdd.Bind(this)
        this.Events["_BtnLog"] := this.BtnLog.Bind(this)
        this.Events["_HotkeyEnter"] := this.BtnAdd.Bind(this)
        this.Events["_ListBoxHandler"] := this.ListBoxHandler.Bind(this)
        this.Events["_SearchBoxHandler"] := this.SearchBoxHandler.Bind(this)

        ; properties
        this.marginSize := 10
        totalWidth := 200
        this.Options("+LabelmobGui_")

        ; controls
        ; this.Add("text", "", "Search")
        this.Add("edit", "w" totalWidth - 45 - this.marginSize " section gmobGui_SearchBoxHandler", "")
        this.Add("button", "x+5 ys-1 w50 gmobGui_BtnHandler", "Add")
        this.Add("listbox", "x" this.marginSize " w" totalWidth " r10 gmobGui_ListBoxHandler", "")
        this.Add("button", "w" totalWidth " gmobGui_BtnHandler", "Log")

        this.Add("picture", "w200 h200 border", "")

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, mobGui_HotkeyEnter
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

        ; update listbox
        GuiControl,, ListBox1 , |
        GuiControl,, ListBox1 , % output
        GuiControl, Choose, ListBox1, % SETTINGS_OBJ.selectedMob
    }

    ListBoxHandler() {
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
        this.Hide()

        FileSelectFile, SelectedFile, 3, , Open a drop log, Text Documents (*.txt)
        if (SelectedFile = "") {
            this.Show()
            return
        }
        PATH_DROP_LOG := SelectedFile

        DROP_TABLE.Get(SETTINGS_OBJ.selectedMob)
        DROP_LOG.Load(PATH_DROP_LOG)
        LOG_GUI.Setup()
    }
}

mobGui_ContextMenu:
    If !(SETTINGS_OBJ.selectedMob)
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
    mobGui.Update()
return

mobGui_ListBoxHandler:
	; call the class's method
    for a, b in class_gui_mob.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_ListBoxHandler"].Call()
return

mobGui_SearchBoxHandler:
	; call the class's method
    for a, b in class_gui_mob.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_SearchBoxHandler"].Call()
return

mobGui_BtnHandler:
    ; get active button text without spaces
    ControlGetFocus, OutputControl, A
    ControlGetText, OutputControlText, % OutputControl, A
    OutputControlText := StrReplace(OutputControlText, A_Space)

    ; call the class's method
    for a, b in class_gui_mob.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
return

mobGui_HotkeyEnter:
	; call the class's method
    for a, b in class_gui_mob.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
return

mobGui_Close:
    ; call the class's method
    for a, b in class_gui_mob.Instances 
		if (a = A_Gui+0)
			b["Events"]["_BtnClose"].Call()
return