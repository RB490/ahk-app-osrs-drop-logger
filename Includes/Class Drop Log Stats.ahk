/*
    ClassStats
        Purpose
            Calculates stats from a drop log

        Usage
            DROP_LOG.Stats.Get()
*/
Class ClassDropLogStats {
    __New(parentInstance) {
        this.parent := parentInstance
        this.UniqueStats := new this.ClassUniqueDropsStats
    }

    Get() {
        output := []

        ; get drop log
        obj := ObjFullyClone(this.parent.obj)

        ; get total stats
        this.GetTotal := new this.ClassGetTotalStats(obj)
        output.totalTrips := totalTrips := this.GetTotal.Trips()
        output.totalKills := totalKills := this.GetTotal.Kills()
        output.totalDrops := totalDrops := this.GetTotal.Drops()
        output.totalDeaths := totalDeaths := this.GetTotal.Deaths()
        output.totalTime := totalTime := this.GetTotal.Time()
        output.totalDeadTime := totalDeadTime := this.GetTotal.DeadTime()
        output.totalValue := totalValue := this.GetTotal.Value()

        ; get average stats
        ; profit
        output.avgProfitPerTrip := avgProfitPerTrip := totalValue / totalTrips
        output.avgProfitPerKill := avgProfitPerKill := totalValue / totalKills
        output.avgProfitPerDrop := avgProfitPerDrop := totalValue / totalDrops
        output.avgProfitPerHour := avgProfitPerHour := totalValue / (totalTime / 3600)

        ; trip
        output.avgKillsPerTrip := avgKillsPerTrip := totalKills / totalTrips
        output.avgDropsPerTrip := avgDropsPerTrip := totalDrops / totalTrips
        
        ; hourly
        output.avgTripsPerHour := avgTripsPerHour := totalTrips / (totalTime / 3600)
        output.avgKillsPerHour := avgKillsPerHour := totalKills / (totalTime / 3600)
        output.avgDropsPerHour := avgDropsPerHour := totalDrops / (totalTime / 3600)

        ; time
        output.avgTimePerTrip := avgTimePerTrip := totalTime / totalTrips
        output.avgTimePerKill := avgTimePerKill := totalTime / totalKills
        output.avgTimePerDrop := avgTimePerDrop := totalTime / totalDrops

        ; average deaths
        output.avgTripsPerDeath := avgTripsPerDeath := totalTrips / totalDeaths
        output.avgKillsPerDeath := avgKillsPerDeath := totalKills / totalDeaths
        output.avgDropsPerDeath := avgDropsPerDeath := totalDrops / totalDeaths
        output.avgProfitPerDeath := avgProfitPerDeath := totalValue / totalDeaths

        ; get unique drops information
        output.uniqueDrops := this.UniqueStats.Get(obj, totalKills)

        return output
    }

    Class ClassGetTotalStats {
        __New(dropLog) {
            this.obj := ObjFullyClone(dropLog)
        }

        Trips() {
            return this.obj.length()
        }

        Kills() {
            obj := this.obj
            loop % obj.length() {
                trip := obj[A_Index]

                output += trip.kills.length()
            }
            return output
        }

        Drops() {
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

        Deaths() {
            obj := this.obj
            loop % obj.length() {
                trip := obj[A_Index]

                output += trip.deaths.length()
            }
            return output
        }

        Time() {
            obj := this.obj
            loop % obj.length() {
                trip := obj[A_Index]

                If !trip.tripEnd
                    trip.tripEnd := A_Now
                
                duration := trip.tripEnd
                EnvSub, duration, % trip.tripStart, Seconds
                output += duration
            }
            return output
        }

        DeadTime() {
            obj := this.obj
            loop % obj.length() {
                trip := obj[A_Index]

                loop % trip.deaths.length() {
                    death := trip.deaths[A_Index]

                    If !death.deathEnd
                        death.deathEnd := A_Now

                    duration := death.deathEnd
                    EnvSub, duration, % death.deathStart, Seconds
                    output += duration
                }
            }
            return output
        }

        Value() {
            obj := this.obj
            loop % obj.length() {
                trip := obj[A_Index]

                loop % trip.kills.length() {
                    kill := trip.kills[A_Index]

                    loop % kill.drops.length() {
                        drop := kill.drops[A_Index]

                        output += ITEM_DB.GetPrice(drop.id)
                    }
                }
            }
            return output
        }
    }

    Class ClassUniqueDropsStats {
        Get(dropLog, totalKills) {
            this.obj := ObjFullyClone(dropLog)
            this.totalKills := totalKills

            this.uniqueDrops := this._getUniqueDrops()

            this._setUniqueDropsTotalValue()
            this._setUniqueDropsDropRate()
            this._setUniqueDropsDryStreak()
            this._setUniqueDropsDryStreakRecords()

            return this.uniqueDrops
        }

        _getUniqueDrops() {
            obj := ObjFullyClone(this.obj)
            output := {}

            loop % obj.length() {
                kills := obj[A_Index].kills
                loop % kills.length() {
                    drops := kills[A_Index].drops

                    loop % drops.length() {
                        drop := drops.pop() ; take & remove drop from source obj

                        ; skip duplicate drops removed by _countAndRemoveUniqueDropsFrom
                        If !IsObject(drop)
                            Continue

                        occurences := 0
                        occurences += this._countAndRemoveUniqueDropsFrom(obj, drop.name, drop.quantity)
                        occurences += 1 ; 'seed'/starting item

                        ; save unique drop and its information to output
                        output.push({name: drop.name, id: drop.id, quantity: drop.quantity, occurences: occurences})
                    }
                }
            }

            return output
        }

        _countAndRemoveUniqueDropsFrom(obj, dropName, dropQuantity) {
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

                        drops.InsertAt(1, drop) ; InsertAt the start of the drop log to prevent same item being popped again during this method
                    }
                }
            }
            return output
        }

        _setUniqueDropsTotalValue() {
            loop % this.uniqueDrops.length() {
                drop := this.uniqueDrops[A_Index]
                totalItems := drop.quantity * drop.occurences
                price := ITEM_DB.GetPrice(drop.id)
                drop.totalValue := totalItems * price
                If !drop.totalValue
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
                                
                                If !match1Found
                                    match1Found := dropIndex
                                else
                                    match2Found := dropIndex

                                If match2Found {
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
}