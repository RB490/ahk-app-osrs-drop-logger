class ClassGuiSettings extends gui {
    Setup() {
        margin := 10
        
        this.Options("-MinimizeBox +LabelsettingsGui_")

        this.Add("checkbox", "x" margin, "Auto show stats")
        If (DB_SETTINGS.logGuiAutoShowStats)
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

        this.Add("button", "x" margin " w140 gsettingsGui_btnSave", "Save")
        
        this.Show()
        DetectHiddenWindows, Off
        WinWaitClose, % this.ahkid
    }

    Save() {
        DB_SETTINGS.logGuiAutoShowStats := this.ControlGet("Checked",,"Button1") ; Auto show stats
        DB_SETTINGS.logGuiDropSize := this.GetText("edit1") ; Item size
        DB_SETTINGS.logGuiMaxRowDrops := this.GetText("edit2") ; Row length
        DB_SETTINGS.logGuiTablesMergeBelowX := this.GetText("edit3") ; Merge tables below
        DB_SETTINGS.logGuiItemImageType := this.GetText("ComboBox1") ; Image type
        this.Close()
    }

    Close() {
        this.hide()
    }
}

settingsGui_btnSave:
    SETTINGS_GUI.Save()
return

settingsGui_close:
    SETTINGS_GUI.Close()
return