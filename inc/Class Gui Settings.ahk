class ClassGuiSettings extends gui {
    Get() {
        margin := 10

        ; set icon
        icoPath := DIR_GUI_ICONS "\osrs_icons\Bounty_Hunter_-_task_config_icon.png"
        ico := new LoadPictureType(icoPath,, 1, "#000000") ; last parameter color will be transparent, you might need to change this.
        this.SetIcon(ico.GetHandle())

        this.Options("-MinimizeBox")

        this.Add("checkbox", "x" margin, "Auto show stats")
        If DB_SETTINGS.logGuiAutoShowStats
            this.Control(, "Button1", true)

        this.Add("groupbox", "h210", "Gui")
            this.Add("text", "xp+" margin " yp+" (margin * 2), "Item size")
            this.Add("edit", "limit2 number")
            this.Add("updown", "range" MIN_DROP_SIZE "-" MAX_DROP_SIZE, DB_SETTINGS.logGuiDropSize)

            this.Add("text",, "Row length")
            this.Add("edit", "limit2 number")
            this.Add("updown", "range" MIN_ROW_LENGTH "-" MAX_ROW_LENGTH, DB_SETTINGS.logGuiMaxRowDrops)

            this.Add("text", , "Merge tables below")
            this.Add("edit", "limit2 number")
            this.Add("updown", "range" MIN_TABLE_SIZE "-99", DB_SETTINGS.logGuiTablesMergeBelowX)

            this.Add("text",, "Image type")
            this.Add("dropdownlist",, ITEM_IMAGE_TYPES)
            this.Control("Choose", "ComboBox1", DB_SETTINGS.logGuiItemImageType)

        this.Add("button", "x" margin " w140", "Save", this.Save.Bind(this))

        this.Show()
        DetectHiddenWindows, Off
        WinWaitClose, % this.ahkid
        return this.savedSettings
    }

    Save() {
        DB_SETTINGS.logGuiAutoShowStats := this.ControlGet("Checked",,"Button1") ; Auto show stats
        DB_SETTINGS.logGuiDropSize := this.GetText("edit1") ; Item size
        DB_SETTINGS.logGuiMaxRowDrops := this.GetText("edit2") ; Row length
        DB_SETTINGS.logGuiTablesMergeBelowX := this.GetText("edit3") ; Merge tables below
        DB_SETTINGS.logGuiItemImageType := this.GetText("ComboBox1") ; Image type
        ValidateSettings()
        this.savedSettings := true
        this.Close()
    }

    Close() {
        this.hide()
    }
}