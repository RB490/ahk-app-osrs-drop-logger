/*
    purpose = anything to do with getting and setting drop log information
        ; example drop log in info\example ClassDropLog.json

    usage = DROP_LOG.Get(filePathString)
        afterwards use the various methods to modify the object
        to finish up DROP_LOG.Save() to save to the selected file

*/

class ClassDropLog {   
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

    ; input = {string} path to existing drop log file
    ; purpose = load drop log into this.obj
    Get(file) {
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
}
