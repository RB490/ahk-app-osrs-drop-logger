Class ClassGuiStats extends gui {
    Get() {
        If this.IsVisible {
            this.Activate()
            return
        }
        
        ; set icon
        icoPath := DIR_GUI_ICONS "\osrs_icons\Leagues_Tutor_icon.png"
        ico := new LoadPictureType(icoPath,, 1, "#000000") ; last parameter color will be transparent, you might need to change this.
        this.SetIcon(ico.GetHandle())
        
        this.options("+Resize")
        this.margin := 5
        margin := this.margin
        this.margin(margin, margin)
        
        this.LvTotal := new this.ListView(this, "x" this.margin " y" this.margin " w165 r7 -hdr", "Stat|Value")

        ControlGetPos , list1X, list1Y, list1W, list1H, , % "ahk_id " this.LvTotal.hwnd
        list2H := SCRIPT_SETTINGS.guiStatsH - list1H - (this.margin * 4) + 2
        this.LvAvg := new this.ListView(this, "w165 h" list2H " -hdr AltSubmit", "Stat|Value", this.AverageListViewHandler.Bind(this))

        list3W := SCRIPT_SETTINGS.guiStatsW - list1W - (this.margin * 3)
        list3H := SCRIPT_SETTINGS.guiStatsH - (this.margin * 2) - 2
        this.LvUnique := new this.ListView(this, "x+" margin " y" margin " w" list3W " h" list3H " r31", "Drop|#|Rate|Value|Dry|<|>|HiddenValueColumnForSorting", this.UniquesListViewHandler.Bind(this))

        this.ShowGui()
        this.CheckPos()
    }

    ; obj = drop log stats received by drop_log.stats.get()
    Set(obj) {
        ; LV_Add(, "----------Total----------", "")
        this.LvTotal.Delete()
        this.LvTotal.Add(, "Trips", obj.totalTrips)
        this.LvTotal.Add(, "Kills", obj.totalKills)
        this.LvTotal.Add(, "Drops", obj.totalDrops)
        this.LvTotal.Add(, "Deaths", obj.totalDeaths)
        this.LvTotal.Add(, "Time", FormatSeconds(obj.totalTime))
        this.LvTotal.Add(, "Dead", FormatSeconds(obj.totalDeadTime))
        this.LvTotal.Add(, "Profit", AddCommas(obj.totalValue))
        this.LvTotal.ModifyCol(1, "AutoHdr")
        this.LvTotal.ModifyCol(2, "AutoHdr")

        ; LV_Add(, "----------Average----------", "")
        this.LvAvg.Delete()
        ; average profit
        this.LvAvg.Add(, "Profit / Trip", AddCommas(Round(obj.avgProfitPerTrip)))
        this.LvAvg.Add(, "Profit / Kill", AddCommas(Round(obj.avgProfitPerKill)))
        this.LvAvg.Add(, "Profit / Drop", AddCommas(Round(obj.avgProfitPerDrop)))
        this.LvAvg.Add(, "Profit / Hour", AddCommas(Round(obj.avgProfitPerHour)))

        ; average trip
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Kills / Trip", Round(obj.avgKillsPerTrip, 2))
        this.LvAvg.Add(, "Drops / Trip", Round(obj.avgDropsPerTrip, 2))

        ; average hourly
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Trips / Hour", Round(obj.avgTripsPerHour, 2))
        this.LvAvg.Add(, "Kills / Hour", Round(obj.avgKillsPerHour, 2))
        this.LvAvg.Add(, "Drops / Hour", Round(obj.avgDropsPerHour))

        ; average time
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Time / Trip", FormatSeconds(obj.avgTimePerTrip))
        this.LvAvg.Add(, "Time / Kill", FormatSeconds(obj.avgTimePerKill))
        this.LvAvg.Add(, "Time / Drop", FormatSeconds(obj.avgTimePerDrop))

        ; average deaths
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Trips / Death", Round(obj.avgTripsPerDeath, 2))
        this.LvAvg.Add(, "Kills / Death", Round(obj.avgKillsPerDeath, 2))
        this.LvAvg.Add(, "Drops / Death", Round(obj.avgDropsPerDeath))
        this.LvAvg.Add(, "Profit / Death", AddCommas(Round(obj.avgProfitPerDeath)))
        this.LvAvg.ModifyCol(1, "AutoHdr")
        this.LvAvg.ModifyCol(2, "AutoHdr")
        this.LvAvg.Modify(this.averageListViewFocusedRow, "Vis")

        ; LV_Add(, "----------Unique----------", "")

        this.LvUnique.Redraw()
        this.LvUnique.Delete()

        ; create image list class
        LvIl := new this.ImageList(obj.uniqueDrops.length())
        this.LvUnique.SetImageList(LvIl.ID)
        loop % obj.uniqueDrops.length() {
            drop := obj.uniqueDrops[A_Index]
            name := drop.name
            id := drop.id
            LvIl.Add(DIR_ITEM_IMAGES_ICONS "\" id ".png") 
        }

        ; load items
        loop % obj.uniqueDrops.length() {
            d := obj.uniqueDrops[A_Index]

            dropRate := Round(d.dropRate, 2)
            commaValue := AddCommas(d.totalValue)
            this.LvUnique.Add("Icon" . A_Index, d.quantity " x " d.name, d.occurences, dropRate, commaValue, d.dryStreak, d.dryStreakRecordLow, d.dryStreakRecordhigh, d.totalValue)
        }

        ; size/scroll
        loop 7
            this.LvUnique.ModifyCol(A_Index, "AutoHdr")
        this.LvUnique.Modify(this.UniquesListViewFocusedRow, "Vis")

        this.LvUnique.Redraw()
    }

    UniquesListViewHandler() {
        ; selected empty space
        If (this.UniquesListViewFocusedRow = 0)
            this.UniquesListViewFocusedRow := ""

        If (A_GuiEvent = "DoubleClick")
            return        
        If (A_GuiEvent = "Normal")
            this.UniquesListViewFocusedRow := this.LvUnique.GetNext(, "Focused")

        ; selected column 4 (total value column) - sort hidden value column
        static t
        If !(A_EventInfo  = 4)
            return
        t := !t
        this.UniquesListViewFocusedRow := ""

        If t
            this.LvUnique.ModifyCol(8, "SortDesc") ; HiddenValueColumnForSorting
        else
            this.LvUnique.ModifyCol(8, "Sort") ; HiddenValueColumnForSorting

    }

    AverageListViewHandler() {
        If (this.averageListViewFocusedRow = 0) ; selected empty space
            this.averageListViewFocusedRow := ""

        If (A_GuiEvent = "Normal") or (A_GuiEvent = "DoubleClick")
            this.averageListViewFocusedRow := this.LvAvg.GetNext(, "Focused")
    }

    Size() {
        AutoXYWH("wh", "SysListView323")
        AutoXYWH("h", "SysListView322", "SysListView323")
    }

    SavePos() {
        WinGetPos(this.hwnd, guiStatsX, guiStatsY, guiStatsW, guiStatsH, true) 
        If !guiStatsW and !guiStatsH
            return
        SCRIPT_SETTINGS.guiStatsX := guiStatsX
        SCRIPT_SETTINGS.guiStatsY := guiStatsY
        SCRIPT_SETTINGS.guiStatsW := guiStatsW
        SCRIPT_SETTINGS.guiStatsH := guiStatsH
    }

    CheckPos() {
        WinGetPos, guiStatsX, guiStatsY, guiStatsW, guiStatsH, % this.ahkid

        If (guiStatsX < 0) ; offscreen-left
            SCRIPT_SETTINGS.guiStatsX := 0
        If (guiStatsY < 0) ; offscreen-top
            SCRIPT_SETTINGS.guiStatsY := 0
        If (guiStatsX + guiStatsW > A_ScreenWidth) ; offscreen-right
            SCRIPT_SETTINGS.guiStatsX := A_ScreenWidth - guiStatsW
        If (guiStatsY + guiStatsH > A_ScreenHeight) ; offscreen-bottom
            SCRIPT_SETTINGS.guiStatsY := A_ScreenHeight - guiStatsH

        If (guiStatsW < 140) ; listview1 width = 175
            SCRIPT_SETTINGS.guiStatsW := 175
        If (guiStatsH < 140) ; listview1 height = 135
            SCRIPT_SETTINGS.guiStatsH := 135

        this.ShowGui()
    }

    ShowGui() {
        If !(SCRIPT_SETTINGS.guiStatsX = "") and !(SCRIPT_SETTINGS.guiStatsY = "") and !(SCRIPT_SETTINGS.guiStatsW = "") and !(SCRIPT_SETTINGS.guiStatsH = "") {
            this.Show("x" SCRIPT_SETTINGS.guiStatsX A_Space "y" SCRIPT_SETTINGS.guiStatsY A_Space "w" SCRIPT_SETTINGS.guiStatsW A_Space "h" SCRIPT_SETTINGS.guiStatsH, "Stats")
        }
        else {
            this.Show(, "Stats")
        }

        this.LvUnique.ModifyCol(2, "Integer") ; occurences
        this.LvUnique.ModifyCol(3, "Integer") ; dropRate
        this.LvUnique.ModifyCol(4, "Integer NoSort") ; totalValue
        this.LvUnique.ModifyCol(5, "Integer") ; dryStreakRecordLow
        this.LvUnique.ModifyCol(6, "Integer") ; dryStreakRecordLow
        this.LvUnique.ModifyCol(7, "Integer") ; dryStreakRecordhigh
        this.LvUnique.ModifyCol(8, "0 Integer") ; HiddenValueColumnForSorting

        SetTimer, updateStats, -1
    }

    Close() {
        SCRIPT_SETTINGS.guiLog_AutoShowStats := false
        STATS_GUI.SavePos()
        STATS_GUI.Hide()
    }
}