; calculates stats based on drop log loaded in 'ClassDropLog'
Class ClassDropStats {
    __New() {
        ; msgbox % A_ThisFunc
    }

    Calculate() {
        this.obj := ObjFullyClone(DROP_LOG.obj)

        timer()
        totalTrips := this._getTotalTrips()
        totalKills := this._getTotalKills()
        totalDrops  := this._getTotalDrops()
        totalDeaths := this._getTotalDeaths()
        totalTime  := this._getTotalTime()
        totalDeadTime  := this._getTotalDeadTime()
        totalDropsValue := this._getTotalDropsValue() ; requires processing
        timer()

        msgbox % totalDropsValue
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