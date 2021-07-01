class ClassGuiSettings extends gui {
    Get() {
        margin := 10

        ; set icon
        icoPath := DIR_GUI_ICONS "\osrs_icons\Bounty_Hunter_-_task_config_icon.png"
        ico := new LoadPictureType(icoPath,, 1, "#000000") ; last parameter color will be transparent, you might need to change this.
        this.SetIcon(ico.GetHandle())

        this.Options("-MinimizeBox")

        this.Add("checkbox", "x" margin, "Auto show stats")
        If SCRIPT_SETTINGS.guiLog_AutoShowStats
            this.Control(, "Button1", true)

        this.Add("groupbox", "h210", "Gui")
            this.Add("text", "xp+" margin " yp+" (margin * 2), "Item size")
            this.Add("edit", "limit2 number")
            this.Add("updown", "range1-999", SCRIPT_SETTINGS.guiLog_DropSize)

            this.Add("text",, "Row length")
            this.Add("edit", "limit2 number")
            this.Add("updown", "range1-999", SCRIPT_SETTINGS.guiLog_MaxRowDrops)

            this.Add("text", , "Merge tables below")
            this.Add("edit", "limit2 number")
            this.Add("updown", "range1-999", SCRIPT_SETTINGS.guiLog_TablesMergeBelowX)

            this.Add("text",, "Image type")
            this.Add("dropdownlist",, GUI_LOG_ITEM_IMAGE_TYPES)
            this.Control("Choose", "ComboBox1", SCRIPT_SETTINGS.guiLog_ItemImageType)

        this.Add("button", "x" margin " w140", "Save", this.Save.Bind(this))

        this.Show(, APP_NAME)
        DetectHiddenWindows, Off
        WinWaitClose, % this.ahkid
        return this.savedSettings
    }

    Save() {
        SCRIPT_SETTINGS.guiLog_AutoShowStats := this.ControlGet("Checked",,"Button1") ; Auto show stats
        SCRIPT_SETTINGS.guiLog_DropSize := this.GetText("edit1") ; Item size
        SCRIPT_SETTINGS.guiLog_MaxRowDrops := this.GetText("edit2") ; Row length
        SCRIPT_SETTINGS.guiLog_TablesMergeBelowX := this.GetText("edit3") ; Merge tables below
        SCRIPT_SETTINGS.guiLog_ItemImageType := this.GetText("ComboBox1") ; Image type
        ValidateSettings()
        this.savedSettings := true
        this.Close()
    }

    Close() {
        this.hide()
    }
}