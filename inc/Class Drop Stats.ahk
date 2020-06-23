; calculates stats based on drop log loaded in 'ClassDropLog'
Class ClassDropStats {
    __New() {
        ; msgbox % A_ThisFunc
    }

    UpdateBasicStats() {
        hwnd := this.hwnd

        this.obj := ObjFullyClone(DROP_LOG.obj)
        stats := {}

        ; total
        stats.totalTrips := totalTrips := this._getTotalTrips()
        stats.totalKills := totalKills := this._getTotalKills() , this.totalKills := totalKills
        stats.totalDrops := totalDrops  := this._getTotalDrops()
        stats.totalDeaths := totalDeaths := this._getTotalDeaths()
        stats.totalTime := totalTime  := this._getTotalTime()
        stats.totalDeadTime := totalDeadTime  := this._getTotalDeadTime()
        stats.totalDropsValue := totalDropsValue := this._getTotalDropsValue()

        ; average profit
        stats.avgProfitPerTrip := avgProfitPerTrip := totalDropsValue / totalTrips
        stats.avgProfitPerKill := avgProfitPerKill := totalDropsValue / totalKills
        stats.avgProfitPerDrop := avgProfitPerDrop := totalDropsValue / totalDrops
        stats.avgProfitPerHour := avgProfitPerHour := totalDropsValue / (totalTime / 3600)

        ; average trip
        stats.avgKillsPerTrip := avgKillsPerTrip := totalKills / totalTrips
        stats.avgDropsPerTrip := avgDropsPerTrip := totalDrops / totalTrips
        
        ; average hourly
        stats.avgTripsPerHour := avgTripsPerHour := totalTrips / (totalTime / 3600)
        stats.avgKillsPerHour := avgKillsPerHour := totalKills / (totalTime / 3600)
        stats.avgDropsPerHour := avgDropsPerHour := totalDrops / (totalTime / 3600)

        ; average time
        stats.avgTimePerTrip := avgTimePerTrip := totalTime / totalTrips
        stats.avgTimePerKill := avgTimePerKill := totalTime / totalKills
        stats.avgTimePerDrop := avgTimePerDrop := totalTime / totalDrops

        ; average deaths
        stats.avgTripsPerDeath := avgTripsPerDeath := totalTrips / totalDeaths
        stats.avgKillsPerDeath := avgKillsPerDeath := totalKills / totalDeaths
        stats.avgDropsPerDeath := avgDropsPerDeath := totalDrops / totalDeaths
        stats.avgProfitPerDeath := avgProfitPerDeath := totalDropsValue / totalDeaths

        STATS_GUI.UpdateBasic(stats)
    }

    UpdateAdvancedStats() {
        this.uniqueDrops := this._getUniqueDrops()
        this._setUniqueDropsTotalValue()
        this._setUniqueDropsDropRate()
        this._setUniqueDropsDryStreak()
        this._setUniqueDropsDryStreakRecords()

        STATS_GUI.UpdateAdvanced(stats)
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

    _getUniqueDrops() {
        inputObj := ObjFullyClone(this.obj)
        output := {}

        loop % inputObj.length() {
            kills := inputObj[A_Index].kills
            loop % kills.length() {
                drops := kills[A_Index].drops

                loop % drops.length() {
                    drop := drops.pop() ; take & remove drop from source obj
                    
                    occurences := 0
                    occurences += this._removeUniqueDrops(inputObj, drop.name, drop.quantity)
                    occurences += 1 ; 'seed'/starting item

                    output.push({name: drop.name, quantity: drop.quantity, occurences: occurences})
                }
            }
        }
        return output
    }

    _removeUniqueDrops(obj, dropName, dropQuantity) {
        loop % obj.length() {
            kills := obj[A_Index].kills

            loop % kills.length() {
                drops := kills[A_Index].drops

                loop % drops.length() {
                    drop := drops.Pop()

                    If (drop.name = dropName) and (drop.quantity = dropQuantity) {
                        output++
                        Continue
                    }

                    drops.InsertAt(1, drop) ; insertat to prevent same item being popped again
                }
            }
        }
        return output
    }

    _setUniqueDropsTotalValue() {
        loop % this.uniqueDrops.length() {
            drop := this.uniqueDrops[A_Index]
            totalItems := drop.quantity * drop.occurences
            price := RUNELITE_API.GetItemPrice(drop.name)
            drop.totalValue := totalItems * price
            If !(drop.totalValue)
                drop.totalValue := "-"
        }
    }

    _setUniqueDropsDropRate() {
        loop % this.uniqueDrops.length() {
            drop := this.uniqueDrops[A_Index]
            drop.dropRate := this.totalKills / drop.occurences
        }
    }
    
    _setUniqueDropsDryStreak() {
        loop % this.uniqueDrops.length() {
            uniqueDropIndex := A_Index
            uniqueDrop := this.uniqueDrops[A_Index]

            loop % this.obj.length() {
                kills := this.obj[A_Index].kills

                loop % kills.length() {
                    drops := kills[A_Index].drops
                    dropIndex++

                    loop % drops.length() {
                        drop := drops[A_Index]

                        If (drop.name = uniqueDrop.name) and (drop.quantity = uniqueDrop.quantity) {
                            output := dropIndex
                            dropIndex := 0
                        }
                    }
                }
            }
            this.uniqueDrops[uniqueDropIndex].dryStreak := output
        }
    }

    _setUniqueDropsDryStreakRecords() {
        loop % this.uniqueDrops.length() {
            uniqueDropIndex := A_Index
            uniqueDrop := this.uniqueDrops[uniqueDropIndex]

            output := {}
            loop % this.obj.length() {
                kills := this.obj[A_Index].kills

                loop % kills.length() {
                    drops := kills[A_Index].drops

                    loop % drops.length() {
                        drop := drops[A_Index]
                        dropIndex++

                        If (drop.name = uniqueDrop.name) and (drop.quantity = uniqueDrop.quantity) {
                            
                            If !(match1Found)
                                match1Found := dropIndex
                            else
                                match2Found := dropIndex

                            If (match2Found) {
                                output[match2Found - match1Found] := ""
                                match1Found := ""
                                match2Found := ""
                            }
                        }
                    }
                }
            }
            this.uniqueDrops[uniqueDropIndex].dryStreakRecordLow := output.MinIndex()
            this.uniqueDrops[uniqueDropIndex].dryStreakRecordHigh := output.MaxIndex()
        }
    }
}