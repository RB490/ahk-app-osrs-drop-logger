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

                        output += ITEM_PRICE.Get(drop.id)
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
                price := ITEM_PRICE.Get(drop.id)
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

        _setUniqueDropsDryStreakNew() {
            loop % this.uniqueDrops.length() {
                uniqueDropIndex := A_Index
                uniqueDrop := this.uniqueDrops[A_Index]
                loopedKills := 0

                loop % this.obj.length() {
                    kills := this.obj[A_Index].kills
                    loopedKills++

                    loop % kills.length() {
                        drops := kills[A_Index].drops

                        loop % drops.length() {
                            drop := drops[A_Index]

                            If (drop.name = uniqueDrop.name) and (drop.quantity = uniqueDrop.quantity) {
                                output := loopedKills
                                loopedKills := 0
                            }
                        }
                    }
                }
                If (loopedKills > 0)
                    output := loopedKills

                ; CoordMode, Tooltip, Screen
                ; tooltip % A_ThisFunc ": _setUniqueDropsDryStreakNew(), output:`n" output,0,0

                this.uniqueDrops[uniqueDropIndex].dryStreak := output
            }
            return output
        }

        _setUniqueDropsDryStreakRecords() {
            /*
                first write 3 separate methods then combine into one

                low record
                high record
                current drystreak

            */

            this._setUniqueDropsDryStreakNew()
            return
            CoordMode, Tooltip, Screen
            tooltip % A_ThisFunc ": _setUniqueDropsDryStreakNew():`n" this._setUniqueDropsDryStreakNew(),0,0
            return
            
                                            /*


                                ; found a pair of drops, calculate and save drystreak
                                If firstMatchFound and secondMatchFound {
                                    drystreaks[dryKills] := dryKills

                                    ; clear variables
                                    firstMatchFound := false
                                    secondMatchFound := false
                                    
                                    ; reset dry streak kills, to start counting kills towards the next first match
                                    dryKills := 0
                                }
                                ; if missing, save either the first or the second match
                                If !firstMatchFound {
                                    firstMatchFound := dryKills
                                    
                                    ; reset dry streak kills, to start counting kills towards the second match
                                    dryKills := 0
                                }
                                else If !secondMatchFound {
                                    secondMatchFound := dryKills
                                    
                                    ; reset dry streak kills
                                    ; dryKills := 0
                                }

                                ; reset dry streak kills
                                dryKills := 0
                                ; found unique drop match
                                ; matchFound := true

                                */

            ; msgbox % json.dump(this.uniqueDrops,,2)

            ; loop unique drops
            For uniqueDropId, uniqueDrop in this.uniqueDrops {
                
                ; set variables for this unique drop
                dryKills := 0
                matchFound := false
                previousKillDrops := {}
                foundDropInPreviousKill := false
                drystreaks := {}

                ; loop trips
                loop % this.obj.length() {
                    kills := this.obj[A_Index].kills

                    ; loop kills
                    loop % kills.length() {
                        drops := kills[A_Index].drops

                        ; loop drops
                        loop % drops.length() {
                            drop := drops[A_Index]

                            ; found unique drop occurence
                            If (drop.name = uniqueDrop.name) and (drop.quantity = uniqueDrop.quantity) {
                                ; if this is the first ever drop; save kills made up until this point as a drystreak
                                If !matchFound {
                                    
                                    drystreaks[dryKills] := dryKills
                                    
                                    dryKills := 0 ; saving the drystreak, therefore this dry streak ends
                                    
                                    matchFound := true

                                    Continue
                                }
                                
                                ; msgbox adding dryKills: %dryKills%
                                drystreaks[dryKills] := dryKills
                                dryKills := 0  ; saving the drystreak, therefore this dry streak ends
                            }
                        }
                        
                        ; count this kill as a dry kill if the previous kill didn't have this unique drop
                        for i, drop in previousKillDrops {
                            ; msgbox % json.dump(previousKillDrops,,2)
                            If (drop.name = uniqueDrop.name) and (drop.quantity = uniqueDrop.quantity) {
                                foundDropInPreviousKill := true
                                ; msgbox % foundDropInPreviousKill
                            }

                        }
                        If !foundDropInPreviousKill and previousKillDrops.length() {
                            dryKills++
                            ; msgbox adding dry kill with: %foundDropInPreviousKill%
                        }

                        ; store current drops
                        previousKillDrops := drops

                        ; msgbox end of loop
                    }
                }
                ; save dry kills made after the last drop
                If (dryKills != false) {
                    dryKills -= dryKills ; -1 to account for <something important> was having a complete brainfar while fixing this method
                    drystreaks[dryKills] := dryKills
                }

                ; save drystreaks
                this.uniqueDrops[uniqueDropId].dryStreakRecordLow := drystreaks.MinIndex()
                this.uniqueDrops[uniqueDropId].dryStreakRecordHigh := drystreaks.MaxIndex()

                ; msgbox completed unique drop loop
            }
            ; msgbox completed method
            return
            
            ; "old"
            loop % this.uniqueDrops.length() {
                uniqueDropIndex := A_Index
                uniqueDrop := this.uniqueDrops[uniqueDropIndex]

                ; msgbox % json.dump(this.uniqueDrops,,2)


                match1Found := ""
                match2Found := ""
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
                                ; msgbox % drop.name " `n`nand`n`n" json.dump(output,,2)
                            }
                        }
                    }
                }
                ; If (uniqueDrop.name = "Avantoe seed")
                    ; msgbox % uniqueDrop.name "`n`n" match1Found "`n`n" match2Found "`n`noutput=`n`n" json.dump(output,,2)


                this.uniqueDrops[uniqueDropIndex].dryStreakRecordLow := output.MinIndex()
                this.uniqueDrops[uniqueDropIndex].dryStreakRecordHigh := output.MaxIndex()

                ; msgbox % json.dump(output,,2)
            }
        }
    }
}