Class ClassGuiStats extends gui {
    Setup() {
        DetectHiddenWindows, On
        If (WinExist, this.ahkid) {
            this.ShowGui()
            this.CheckPos()
            return
        }
        
        this.options("+LabelguiStats_ +Resize")
        this.margin := 5
        margin := this.margin
        this.margin(margin, margin)
        
        ; this.add("text", "", "Total")
        this.add("listview", "x" this.margin " w165 r7 -hdr", "Stat|Value")
        ; this.add("text", "", "Average")
        this.add("listview", "w165 h230 -hdr AltSubmit gguiStats_averageListView", "Stat|Value")

        this.add("listview", "x+" margin " y" margin " w550 h358 r31 AltSubmit gguiStats_advancedListView", "Drop|#|Rate|Value|Dry|<|>|HiddenValueColumnForSorting")

        this.ShowGui()
        this.CheckPos()
    }

    ; stats = {object} from stats class
    RedrawBasic(stats) {
        this.SetDefault()
        
        Gui % this.hwnd ":ListView", SysListView321
        LV_Delete()
        ; LV_Add(, "----------Total----------", "")
        LV_Add(, "Trips", stats.totalTrips)
        LV_Add(, "Kills", stats.totalKills)
        LV_Add(, "Drops", stats.totalDrops)
        LV_Add(, "Deaths", stats.totalDeaths)
        LV_Add(, "Time", FormatSeconds(stats.totalTime))
        LV_Add(, "Dead", FormatSeconds(stats.totalDeadTime))
        LV_Add(, "Profit", AddCommas(stats.totalDropsValue))
        LV_ModifyCol(, "AutoHdr")

        Gui % this.hwnd ":ListView", SysListView322
        LV_Delete()
        ; LV_Add(, "----------Average----------", "")
        ; average profit
        LV_Add(, "Profit / Trip", AddCommas(Round(stats.avgProfitPerTrip)))
        LV_Add(, "Profit / Kill", AddCommas(Round(stats.avgProfitPerKill)))
        LV_Add(, "Profit / Drop", AddCommas(Round(stats.avgProfitPerDrop)))
        LV_Add(, "Profit / Hour", AddCommas(Round(stats.avgProfitPerHour)))

        ; average trip
        LV_Add(, "", "")
        LV_Add(, "Kills / Trip", Round(stats.avgKillsPerTrip, 2))
        LV_Add(, "Drops / Trip", Round(stats.avgDropsPerTrip, 2))

        ; average hourly
        LV_Add(, "", "")
        LV_Add(, "Trips / Hour", Round(stats.avgTripsPerHour, 2))
        LV_Add(, "Kills / Hour", Round(stats.avgKillsPerHour, 2))
        LV_Add(, "Drops / Hour", Round(stats.avgDropsPerHour))

        ; average time
        LV_Add(, "", "")
        LV_Add(, "Time / Trip", FormatSeconds(stats.avgTimePerTrip))
        LV_Add(, "Time / Kill", FormatSeconds(stats.avgTimePerKill))
        LV_Add(, "Time / Drop", FormatSeconds(stats.avgTimePerDrop))

        ; average deaths
        LV_Add(, "", "")
        LV_Add(, "Trips / Death", Round(stats.avgTripsPerDeath, 2))
        LV_Add(, "Kills / Death", Round(stats.avgKillsPerDeath, 2))
        LV_Add(, "Drops / Death", Round(stats.avgDropsPerDeath))
        LV_Add(, "Profit / Death", AddCommas(Round(stats.avgProfitPerDeath)))
        LV_ModifyCol(, "AutoHdr")
        LV_Modify(this.averageListViewFocusedRow, "Vis")
    }

    RedrawAdvanced() {
        this.SetDefault()
        Gui % this.hwnd ":ListView", SysListView323
        GuiControl % this.hwnd ":-Redraw", SysListView323
        LV_Delete()

        ; create image list
        ImageListID := IL_Create(DROP_STATS.uniqueDrops.length())
        LV_SetImageList(ImageListID)
        loop % DROP_STATS.uniqueDrops.length() {
            name := DROP_STATS.uniqueDrops[A_Index].name
            id := RUNELITE_API.GetItemId(name)
            IL_Add(ImageListID, DIR_ITEM_RUNELITE "\" id ".png", , 1) ; ResizeNonIcon even though it doesnt seem to make a difference
        }

        ; load items
        loop % DROP_STATS.uniqueDrops.length() {
            d := DROP_STATS.uniqueDrops[A_Index]

            dropRate := Round(d.dropRate, 2)
            commaValue := AddCommas(d.totalValue)
            LV_Add("Icon" . A_Index, d.quantity " x " d.name, d.occurences, dropRate, commaValue, d.dryStreak, d.dryStreakRecordLow, d.dryStreakRecordhigh, d.totalValue)
        }

        ; size/scroll
        loop 10
            LV_ModifyCol(A_Index, "AutoHdr")
        LV_ModifyCol(8, 0) ; HiddenValueColumnForSorting
        LV_Modify(this.advancedListViewFocusedRow, "Vis")

        GuiControl % this.hwnd ":+Redraw", SysListView323
    }

    AdvancedListViewHandler() {
        Gui % this.hwnd ":ListView", SysListView323

        ; selected empty space
        If (this.advancedListViewFocusedRow = 0)
            this.advancedListViewFocusedRow := ""

        ; selected left click or double click
        If (A_GuiEvent = "Normal") or (A_GuiEvent = "DoubleClick")
            this.advancedListViewFocusedRow := LV_GetNext(, "Focused")

        ; selected column 4 (total value column) - sort hidden value column
        static t
        If !(A_EventInfo  = 4)
            return
        t := !t
        this.advancedListViewFocusedRow := ""

        If (t)
            LV_ModifyCol(8, "SortDesc") ; HiddenValueColumnForSorting
        else
            LV_ModifyCol(8, "Sort") ; HiddenValueColumnForSorting
    }

    AverageListViewHandler() {
        Gui % this.hwnd ":ListView", SysListView322

        If (this.averageListViewFocusedRow = 0) ; selected empty space
            this.averageListViewFocusedRow := ""

        If (A_GuiEvent = "Normal") or (A_GuiEvent = "DoubleClick")
            this.averageListViewFocusedRow := LV_GetNext(, "Focused")
    }

    Resize() {
        ; A_GuiWidth A_GuiHeight
        STATS_GUI.SetDefault() ; for guicontrol

        ControlGetPos , list1X, list1Y, list1W, list1H, SysListView321

        GuiControl, MoveDraw, SysListView322, % "h" A_GuiHeight - list1H - (this.margin * 4) + 2

        GuiControl, MoveDraw, SysListView323, % "h" A_GuiHeight - (this.margin * 2)
        GuiControl, MoveDraw, SysListView323, % "w" A_GuiWidth - list1W - (this.margin * 3)
    }

    SavePos() {
        If !(WinExist(this.ahkid))
            return
        WinGetPos(this.hwnd, guiStatsX, guiStatsY, guiStatsW, guiStatsH, true) 
        DB_SETTINGS.guiStatsX := guiStatsX
        DB_SETTINGS.guiStatsY := guiStatsY
        DB_SETTINGS.guiStatsW := guiStatsW
        DB_SETTINGS.guiStatsH := guiStatsH
    }

    CheckPos() {
        WinGetPos, guiStatsX, guiStatsY, guiStatsW, guiStatsH, % this.ahkid

        If (guiStatsX < 0) ; offscreen-left
            DB_SETTINGS.guiStatsX := 0
        If (guiStatsY < 0) ; offscreen-top
            DB_SETTINGS.guiStatsY := 0
        If (guiStatsX + guiStatsW > A_ScreenWidth) ; offscreen-right
            DB_SETTINGS.guiStatsX := A_ScreenWidth - guiStatsW
        If (guiStatsY + guiStatsH > A_ScreenHeight) ; offscreen-bottom
            DB_SETTINGS.guiStatsY := A_ScreenHeight - guiStatsH

        If (guiStatsW < 175) ; listview1 width = 175
            DB_SETTINGS.guiStatsW := 250
        If (guiStatsH < 135) ; listview1 height = 135
            DB_SETTINGS.guiStatsH := 250

        this.ShowGui()
    }

    ShowGui() {
        If !(DB_SETTINGS.guiStatsX = "") and !(DB_SETTINGS.guiStatsY = "") and !(DB_SETTINGS.guiStatsW = "") and !(DB_SETTINGS.guiStatsH = "") {
            this.Show("x" DB_SETTINGS.guiStatsX A_Space "y" DB_SETTINGS.guiStatsY A_Space "w" DB_SETTINGS.guiStatsW A_Space "h" DB_SETTINGS.guiStatsH)
        }
        else {
            this.Show()
        }

        this.SetDefault()
        Gui % this.hwnd ":ListView", SysListView323
        LV_ModifyCol(2, "Integer") ; occurences
        LV_ModifyCol(3, "Integer") ; dropRate
        LV_ModifyCol(4, "Integer NoSort") ; totalValue
        LV_ModifyCol(6, "Integer") ; dryStreakRecordLow
        LV_ModifyCol(7, "Integer") ; dryStreakRecordhigh
        LV_ModifyCol(8, "0 Integer") ; HiddenValueColumnForSorting

        SetTimer, updateStats, -1
    }

    Close() {
        DB_SETTINGS.AutoShowStats := false
        STATS_GUI.SavePos()
        STATS_GUI.Hide()
    }
}

guiStats_advancedListView:
    STATS_GUI.AdvancedListViewHandler()
return

guiStats_averageListView:
    STATS_GUI.AverageListViewHandler()
return

guiStats_close:
    STATS_GUI.Close()
return

guiStats_size:
    STATS_GUI.Resize()
return