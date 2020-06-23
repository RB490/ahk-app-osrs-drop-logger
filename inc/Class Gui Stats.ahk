Class ClassGuiStats extends gui {
    Setup() {
        DetectHiddenWindows, On
        If (WinExist, this.ahkid) {
            this.Show()
            return
        }
        
        this.options("+LabelguiStats_")
        margin := 5
        this.margin(margin, margin)
        
        ; this.add("text", "", "Total")
        this.add("listview", "w165 r7 -hdr", "Stat|Value")
        ; this.add("text", "", "Average")
        this.add("listview", "w165 h230 -hdr", "Stat|Value")

        this.add("listview", "x+" margin " y" margin " w550 h358 r31 gguiStats_advancedListView", "Drop|#|Rate|Value|Dry|<|>|HiddenValueColumnForSorting")
        LV_ModifyCol(2, "Integer") ; occurences
        LV_ModifyCol(3, "Integer") ; dropRate
        LV_ModifyCol(4, "Integer NoSort") ; totalValue
        LV_ModifyCol(5, 30) ; dry streak
        LV_ModifyCol(6, "Integer") ; dryStreakRecordLow
        LV_ModifyCol(7, "Integer") ; dryStreakRecordhigh
        LV_ModifyCol(8, "0 Integer") ; HiddenValueColumnForSorting

        this.show()
    }

    ; stats = {object} from stats class
    UpdateBasic(stats) {
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
    }

    UpdateAdvanced() {
        Gui % this.hwnd ":ListView", SysListView323
        GuiControl % this.hwnd ":-Redraw", SysListView323
        LV_Delete()
        loop % DROP_STATS.uniqueDrops.length() {
            d := DROP_STATS.uniqueDrops[A_Index]

            dropRate := Round(d.dropRate, 2)
            commaValue := AddCommas(d.totalValue)
            ; totalValue := StrReplace(totalValue, ",", ".") ; for listview column sorting
            LV_Add(, d.name " x " d.quantity, d.occurences, dropRate, commaValue, d.dryStreak, d.dryStreakRecordLow, d.dryStreakRecordhigh, d.totalValue)
        }
        LV_ModifyCol(, "AutoHdr")
        LV_ModifyCol(5, 30) ; dry streak
        ; LV_ModifyCol(8, 0) ; HiddenValueColumnForSorting
        GuiControl % this.hwnd ":+Redraw", SysListView323
    }

    AdvancedListViewHandler() {
        static s
        If !(A_EventInfo  = 4) ; total value
            return
        s := !s

        Gui % this.hwnd ":ListView", SysListView323
        GuiControl % this.hwnd ":-Redraw", SysListView323

        If (s)
            LV_ModifyCol(8, "SortDesc") ; HiddenValueColumnForSorting
        else
            LV_ModifyCol(8, "Sort") ; HiddenValueColumnForSorting


        GuiControl % this.hwnd ":+Redraw", SysListView323
    }
}

guiStats_advancedListView:
    STATS_GUI.AdvancedListViewHandler()
return

guiStats_close:
    STATS_GUI.Hide()
return