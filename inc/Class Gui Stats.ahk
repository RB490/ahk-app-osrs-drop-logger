Class ClassGuiStats extends gui {
    Setup() {
        this.add("listview", "r31", "Stat|Value")
        this.show()
    }

    ; stats = {object} from stats class
    Update(stats) {
        LV_Delete()
        
        LV_Add(, "----------Total----------", "")
        LV_Add(, "Trips", stats.totalTrips)
        LV_Add(, "Kills", stats.totalKills)
        LV_Add(, "Drops", stats.totalDrops)
        LV_Add(, "Deaths", stats.totalDeaths)
        LV_Add(, "Time", FormatSeconds(stats.totalTime))
        LV_Add(, "Time Dead", FormatSeconds(stats.totalDeadTime))
        LV_Add(, "Profit", AddCommas(stats.totalDropsValue))

        LV_Add(, "----------Average----------", "")
        ; average profit
        LV_Add(, "---Profit---", "")
        LV_Add(, "Profit Per Trip", AddCommas(Round(stats.avgProfitPerTrip)))
        LV_Add(, "Profit Per Kill", AddCommas(Round(stats.avgProfitPerKill)))
        LV_Add(, "Profit Per Drop", AddCommas(Round(stats.avgProfitPerDrop)))
        LV_Add(, "Profit Per Hour", AddCommas(Round(stats.avgProfitPerHour)))

        ; average trip
        LV_Add(, "---Trip---", "")
        LV_Add(, "Kills Per Trip", Round(stats.avgKillsPerTrip, 2))
        LV_Add(, "Drops Per Trip", Round(stats.avgDropsPerTrip, 2))

        ; average time
        LV_Add(, "---Time---", "")
        LV_Add(, "Trips Per Hour", Round(stats.avgTripsPerHour, 2))
        LV_Add(, "Kills Per Hour", Round(stats.avgKillsPerHour, 2))
        LV_Add(, "Drops Per Hour", Round(stats.avgDropsPerHour))

        LV_Add(, "Time Per Trip", FormatSeconds(stats.avgTimePerTrip))
        LV_Add(, "Time Per Kill", FormatSeconds(stats.avgTimePerKill))
        LV_Add(, "Time Per Drop", FormatSeconds(stats.avgTimePerDrop))

        ; average deaths
        LV_Add(, "---Deaths---", "")
        LV_Add(, "Trips Per Death", Round(stats.avgTripsPerDeath, 2))
        LV_Add(, "Kills Per Death", Round(stats.avgKillsPerDeath, 2))
        LV_Add(, "Drops Per Death", Round(stats.avgDropsPerDeath))
        LV_Add(, "Profit Per Death", AddCommas(Round(stats.avgProfitPerDeath)))


        LV_ModifyCol(, "AutoHdr")
    }
}