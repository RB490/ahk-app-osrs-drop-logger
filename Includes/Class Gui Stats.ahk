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
        this.LvUnique := new this.ListView(this, "x+" margin " y" margin " w" list3W " h" list3H " r31", "Drop|#|Rate|Value|Dry|<|>|HiddenValueColumnForSorting", this.AdvancedListViewHandler.Bind(this))

        this.ShowGui()
        this.CheckPos()
    }

    ; stats = {object} from stats class
    RedrawBasic(stats) {
        ; LV_Add(, "----------Total----------", "")
        this.LvTotal.Delete()
        this.LvTotal.Add(, "Trips", stats.totalTrips)
        this.LvTotal.Add(, "Kills", stats.totalKills)
        this.LvTotal.Add(, "Drops", stats.totalDrops)
        this.LvTotal.Add(, "Deaths", stats.totalDeaths)
        this.LvTotal.Add(, "Time", FormatSeconds(stats.totalTime))
        this.LvTotal.Add(, "Dead", FormatSeconds(stats.totalDeadTime))
        this.LvTotal.Add(, "Profit", AddCommas(stats.totalDropsValue))
        this.LvTotal.ModifyCol(1, "AutoHdr")
        this.LvTotal.ModifyCol(2, "AutoHdr")

        ; LV_Add(, "----------Average----------", "")
        this.LvAvg.Delete()
        ; average profit
        this.LvAvg.Add(, "Profit / Trip", AddCommas(Round(stats.avgProfitPerTrip)))
        this.LvAvg.Add(, "Profit / Kill", AddCommas(Round(stats.avgProfitPerKill)))
        this.LvAvg.Add(, "Profit / Drop", AddCommas(Round(stats.avgProfitPerDrop)))
        this.LvAvg.Add(, "Profit / Hour", AddCommas(Round(stats.avgProfitPerHour)))

        ; average trip
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Kills / Trip", Round(stats.avgKillsPerTrip, 2))
        this.LvAvg.Add(, "Drops / Trip", Round(stats.avgDropsPerTrip, 2))

        ; average hourly
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Trips / Hour", Round(stats.avgTripsPerHour, 2))
        this.LvAvg.Add(, "Kills / Hour", Round(stats.avgKillsPerHour, 2))
        this.LvAvg.Add(, "Drops / Hour", Round(stats.avgDropsPerHour))

        ; average time
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Time / Trip", FormatSeconds(stats.avgTimePerTrip))
        this.LvAvg.Add(, "Time / Kill", FormatSeconds(stats.avgTimePerKill))
        this.LvAvg.Add(, "Time / Drop", FormatSeconds(stats.avgTimePerDrop))

        ; average deaths
        this.LvAvg.Add(, "", "")
        this.LvAvg.Add(, "Trips / Death", Round(stats.avgTripsPerDeath, 2))
        this.LvAvg.Add(, "Kills / Death", Round(stats.avgKillsPerDeath, 2))
        this.LvAvg.Add(, "Drops / Death", Round(stats.avgDropsPerDeath))
        this.LvAvg.Add(, "Profit / Death", AddCommas(Round(stats.avgProfitPerDeath)))
        this.LvAvg.ModifyCol(1, "AutoHdr")
        this.LvAvg.ModifyCol(2, "AutoHdr")
        this.LvAvg.Modify(this.averageListViewFocusedRow, "Vis")
    }

    RedrawAdvanced() {
        this.LvUnique.Redraw()
        this.LvUnique.Delete()

        ; create image list class
        LvIl := new this.ImageList(DROP_STATS.uniqueDrops.length())
        this.LvUnique.SetImageList(LvIl.ID)
        loop % DROP_STATS.uniqueDrops.length() {
            name := DROP_STATS.uniqueDrops[A_Index].name
            id := RUNELITE_API.GetItemId(name)
            LvIl.Add(DIR_ITEM_RUNELITE "\" id ".png") 
        }

        ; load items
        loop % DROP_STATS.uniqueDrops.length() {
            d := DROP_STATS.uniqueDrops[A_Index]

            dropRate := Round(d.dropRate, 2)
            commaValue := AddCommas(d.totalValue)
            this.LvUnique.Add("Icon" . A_Index, d.quantity " x " d.name, d.occurences, dropRate, commaValue, d.dryStreak, d.dryStreakRecordLow, d.dryStreakRecordhigh, d.totalValue)
        }

        ; size/scroll
        loop 7
            this.LvUnique.ModifyCol(A_Index, "AutoHdr")
        this.LvUnique.Modify(this.advancedListViewFocusedRow, "Vis")

        this.LvUnique.Redraw()
    }

    AdvancedListViewHandler() {
        ; selected empty space
        If (this.advancedListViewFocusedRow = 0)
            this.advancedListViewFocusedRow := ""

        If (A_GuiEvent = "DoubleClick")
            return        
        If (A_GuiEvent = "Normal")
            this.advancedListViewFocusedRow := this.LvUnique.GetNext(, "Focused")

        ; selected column 4 (total value column) - sort hidden value column
        static t
        If !(A_EventInfo  = 4)
            return
        t := !t
        this.advancedListViewFocusedRow := ""

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