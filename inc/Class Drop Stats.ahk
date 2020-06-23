; calculates stats based on drop log loaded in 'ClassDropLog'
Class ClassDropStats {
    __New() {
        ; msgbox % A_ThisFunc
    }

    Calculate() {
        stats := {}
        this.obj := ObjFullyClone(DROP_LOG.obj)

        ; timer()

        ; total
        totalTrips := this._getTotalTrips()                         , stats.totalTrips := totalTrips
        totalKills := this._getTotalKills()                         , stats.totalKills := totalKills
        totalDrops  := this._getTotalDrops()                        , stats.totalDrops := totalDrops
        totalDeaths := this._getTotalDeaths()                       , stats.totalDeaths := totalDeaths
        totalTime  := this._getTotalTime()                          , stats.totalTime := totalTime
        totalDeadTime  := this._getTotalDeadTime()                  , stats.totalDeadTime := totalDeadTime
        totalDropsValue := this._getTotalDropsValue()               , stats.totalDropsValue := totalDropsValue

        ; average profit
        avgProfitPerTrip := totalDropsValue / totalTrips            , stats.avgProfitPerTrip := avgProfitPerTrip
        avgProfitPerKill := totalDropsValue / totalKills            , stats.avgProfitPerKill := avgProfitPerKill
        avgProfitPerDrop := totalDropsValue / totalDrops            , stats.avgProfitPerDrop := avgProfitPerDrop
        avgProfitPerHour := totalDropsValue / (totalTime / 3600)    , stats.avgProfitPerHour := avgProfitPerHour

        ; average trip
        avgKillsPerTrip := totalKills / totalTrips                  , stats.avgKillsPerTrip := avgKillsPerTrip
        avgDropsPerTrip := totalDrops / totalTrips                  , stats.avgDropsPerTrip := avgDropsPerTrip
        
        ; average time
        avgTripsPerHour := totalTrips / (totalTime / 3600)          , stats.avgTripsPerHour := avgTripsPerHour
        avgKillsPerHour := totalKills / (totalTime / 3600)          , stats.avgKillsPerHour := avgKillsPerHour
        avgDropsPerHour := totalDrops / (totalTime / 3600)          , stats.avgDropsPerHour := avgDropsPerHour

        avgTimePerTrip := totalTime / totalTrips                    , stats.avgTimePerTrip := avgTimePerTrip
        avgTimePerKill := totalTime / totalKills                    , stats.avgTimePerKill := avgTimePerKill
        avgTimePerDrop := totalTime / totalDrops                    , stats.avgTimePerDrop := avgTimePerDrop

        ; average deaths
        avgTripsPerDeath := totalTrips / totalDeaths                , stats.avgTripsPerDeath := avgTripsPerDeath
        avgKillsPerDeath := totalKills / totalDeaths                , stats.avgKillsPerDeath := avgKillsPerDeath
        avgDropsPerDeath := totalDrops / totalDeaths                , stats.avgDropsPerDeath := avgDropsPerDeath
        avgProfitPerDeath := totalDropsValue / totalDeaths          , stats.avgProfitPerDeath := avgProfitPerDeath

        ; timer()

        ; msgbox % json.dump(stats,,2)
        STATS_GUI.Update(stats)
    }

    _getTotalTrips() {
        return this.obj.length()
    }

    _getTotalKills() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            output += trip.kills.length()
        }
        return output
    }

    _getTotalDrops() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            loop % trip.kills.length() {
                kill := trip.kills[A_Index]

                output += kill.drops.length()
            }
        }
        return output
    }

    _getTotalDeaths() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            output += trip.deaths.length()
        }
        return output
    }

    _getTotalTime() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            If !(trip.tripEnd)
                trip.tripEnd := A_Now
            
            duration := trip.tripEnd
            EnvSub, duration, % trip.tripStart, Seconds
            output += duration
        }
        return output
    }

    _getTotalDeadTime() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            loop % trip.deaths.length() {
                death := trip.deaths[A_Index]

                If !(death.deathEnd)
                    death.deathEnd := A_Now

                duration := death.deathEnd
                EnvSub, duration, % death.deathStart, Seconds
                output += duration
            }
        }
        return output
    }

    _getTotalDropsValue() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            loop % trip.kills.length() {
                kill := trip.kills[A_Index]

                loop % kill.drops.length() {
                    drop := kill.drops[A_Index]

                    output += RUNELITE_API.GetItemPrice(drop.name)
                }
            }
        }
        return output
    }
}