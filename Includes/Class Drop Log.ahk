/*
    purpose = anything to do with getting and setting drop log information
        ; example drop log in info\example ClassDropLog.json

    usage = DROP_LOG.LoadFile(filePathString)
        afterwards use the various methods to modify the object
        to finish up DROP_LOG.Save() to save to the selected file

*/

class ClassDropLog {   
    __New() {
        this.Stats := new this.ClassStats(this)
    }
    
    ; usage = DROP_LOG.isLoaded
    isLoaded[] {
        get {
            If IsObject(this.obj)
                return true
            return
        }
    }

    ; usage = CLASS_INSTANCE.GetObj
    GetObj[] {
        get {
            If !IsObject(this.obj)
                return false
            return this.obj
        }
    }

    Get() {
        return this.obj
    }

    ; input = {string} path to existing drop log file
    ; purpose = load drop log into this.obj
    LoadFile(file) {
        If !file
            Msg("Error", A_ThisFunc, "Can't log without a log file")

        this.file := file
        this.undoActions := {}
        this.redoActions := {}
        
        ; empty file
        fileContent := FileRead(this.file)
        If !fileContent {
            this.obj := {}
            return true
        }

        result := json.load(fileContent)
        
        ; invalid file
        If !IsObject(result) {
            this.obj := {}
            Msg("Error", A_ThisFunc, "'" this.file "' does not contain a valid json or is damaged")
            return false
        }
        
        this.obj := result
        return true
    }

    ; output = {string} entire drop log formatted
    GetFormattedLog() {

        ; build key:value object where key is event timestamp and value the event
        output := {}
        loop % this.obj.length() {
            trip := this.obj[A_Index]
            output[trip.tripStart] := "Trip Start" ; add trip start
            output[trip.tripEnd] := "Trip End" ; add trip end

            ; add kills
            loop % trip.kills.length() {
                killEnd := trip.kills[A_Index].killEnd
                killDrops := trip.kills[A_Index].drops

                drops := ""
                loop % killDrops.length() {
                    drop := killDrops[A_Index]
                    
                    drops .= drop.quantity " x " drop.name ", "
                }
                drops := RTrim(drops, ", ")
                output[killEnd] := drops
            }

            ; add deaths
            loop % trip.deaths.length() {
                death := trip.deaths[A_Index]

                output[death.deathStart] := "Death Start" ; add death start
                output[death.deathEnd] := "Death End" ; add death end
            }
        }
        output.Delete("") ; empty key can be created when there is no timestamp available for death/trip start/end

        ; build formatted string output
        for key, value in output {
            ; ignore
            If InStr(value, "Death End")
                Continue
            
            ; prettify
            If InStr(value, "Death Start")
                value := "*Death*"
            If InStr(value, "trip")
                value := "----------------------" value "----------------------"
            
            If InStr(value, "trip")
                output .= "`n"

            output .= "`n" value
            
            If InStr(value, "trip")
                output .= "`n"
        }
        output := LTrim(output, "`n")
        ; output := RTrim(output, "`n")
        return output
    }

    ; output = {string} <current trip> drops formatted
    GetFormattedTrip() {
    }

    Save() {
        If A_IsCompiled { ; prevent stats being messed up by trip ongoing while program isnt running
            If DROP_LOG.TripActive()
                DROP_LOG.EndTrip()
            If DROP_LOG.DeathActive()
                DROP_LOG.EndDeath()
        }
        FileDelete, % this.file
        FileAppend, % json.dump(this.obj,,2), % this.file
    }

    Undo() {
        If !this.undoActions.length() {
            Msg("Info", A_ThisFunc, "Nothing to undo!")
            return
        }
        this.redoActions.push(this.obj)
        obj := this.undoActions.pop()
        this.obj := obj
    }

    Redo() {
        If !this.redoActions.length() {
            Msg("Info", A_ThisFunc, "Nothing to redo!")
            return
        }
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.redoActions.pop()
        this.obj := obj
    }

    ; input = {object} retrieved by DROP_TABLE.GetDrop() containing drop information
    AddKill(input) {
        If !input.length()
            return

        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        kill := {}
        kill.killEnd := this._ConvertTimeStamp("encode", A_Now)
        kill.drops := input

        trip := this.obj[this.obj.length()]
        kills := trip.kills.push(kill)
        return true
    }

    StartTrip() {
        If this.TripActive() {
            Msg("Info", A_ThisFunc, "Trip already started!")
            return false
        }
        
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := {}
        obj.kills := {}
        obj.deaths := {}
        obj.tripStart := this._ConvertTimeStamp("encode", A_Now)
        obj.tripEnd := ""
        this.obj.push(obj)
    }

    EndTrip() {
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.tripEnd := this._ConvertTimeStamp("encode", A_Now)
    }

    ToggleTrip() {
        If this.TripActive()
            this.EndTrip()
        else
            this.StartTrip()
    }

    NewTrip() {
        If this.TripActive()
            this.EndTrip()
        this.StartTrip()
    }

    TripActive() {
        obj := this.obj[this.obj.length()]
        If obj.tripEnd or !IsObject(obj)
            return false
        return true
    }

    StartDeath() {
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.deaths.push({"deathStart": this._ConvertTimeStamp("encode", A_Now)})
    }

    EndDeath() {
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()].deaths
        obj := obj[obj.length()]
        obj.deathEnd := this._ConvertTimeStamp("encode", A_Now)
    }

    ToggleDeath() {
        If this.DeathActive()
            this.EndDeath()
        else
            this.StartDeath()
    }

    DeathActive() {
        obj := this.obj[this.obj.length()].deaths
        obj := obj[obj.length()]
        
        If obj.deathStart and !obj.deathEnd
            return true
    }

    ; input = {string} 'encode' or 'decode'
    ; purpose = DROP_LOG.GetFormattedLog() uses timestamps to put events in the right order,
    ;   add A_MSec to prevent multiple actions in the same second overwriting eachother
    ; note = turns out decoding isn't necessary as 'EnvAdd' / 'EnvSub' ignore the added msecs
    _ConvertTimeStamp(encodeOrDecode, timeStamp) {
        sleep 1 ; wait 1 milisecond so actions in DROP_LOG.GetFormattedLog() don't execute on the same milisecond
        
        If (encodeOrDecode = "encode") {
            output := timeStamp A_MSec
        }

        If (encodeOrDecode = "decode")
            output := SubStr(timeStamp, 1, StrLen(timeStamp) - 3)

        return output
    }

    /*
        ClassStats
            Purpose
                Calculates stats from a drop log

            Usage
                DROP_LOG.Stats.Get()
    */
    Class ClassStats {
        __New(parentInstance) {
            this.parent := parentInstance
            this.uniqueDropsStats := new this.ClassUniqueDropsStats
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
            output.uniqueDrops := this.ClassUniqueDropsStats.Get(obj, totalKills)

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
}
