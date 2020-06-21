; calculates stats based on drop log loaded in 'ClassDropLog'
Class ClassDropStats {
    __New() {
        ; msgbox % A_ThisFunc
    }

    Calculate() {
        this.obj := ObjFullyClone(DROP_LOG.obj)

        ; timer()
        totalKills := this._getTotalKills()
        totalDeaths := this._getTotalDeaths()
        totalTrips := this._getTotalTrips()
        totalTime  := this._getTotalTime()
        totalDeadTime  := this._getTotalDeadTime()
        ; timer()

        msgbox % totalDeadTime
    }

    _getTotalKills() {
        obj := this.obj
        loop % obj.length() {
            trip := obj[A_Index]

            output += trip.kills.length()
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

    _getTotalTrips() {
        return this.obj.length()
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
}