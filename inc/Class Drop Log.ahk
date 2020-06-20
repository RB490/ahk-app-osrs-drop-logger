; output example in info\example class_drop_log.json
class class_drop_log {   
    ; output = {string} containing current trip drops
    Get() {
        obj := this.obj[this.obj.length()].drops
        loop % obj.length() {
            kill := A_Index
            loop % obj[A_Index].length()
                drops .= obj[kill][A_Index].quantity " x " obj[kill][A_Index].name ", "
            
            drops := RTrim(drops, ", ")
            drops .= "`r `n"
        }
        return drops
    }

    ; (optional) input = {string} path to existing drop log file
    ; purpose = create drop log object
    Load(logFile:="") {
        If !(logFile)
            this._SetFile()

        this.undoActions := {}
        this.redoActions := {}

        content := json.load(FileRead(PATH_DROP_LOG))
        If (IsObject(content))
            this.obj := content
        else
            this.obj := {}
    }

    _SetFile() {
        FileSelectFile, SelectedFile, 2, % manageGui.GetText("Edit1"), Select drop log, Json (*.json)
        If !(SelectedFile) {
            msgbox, 4160, , % A_ThisFunc ": Can't log without a log file"
            reload
        }
        SplitPath, SelectedFile , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
        PATH_DROP_LOG := OutDir "\" OutNameNoExt ".json"
    }

    Save() {
        If !(this.obj.length())
            return
        FileDelete, % PATH_DROP_LOG
        FileAppend, % json.dump(this.obj,,2), % PATH_DROP_LOG
    }

    Undo() {
        If !(this.undoActions.length()) {
            msgbox, 4160, , % A_ThisFunc ": Nothing to undo!"
            return
        }
        this.redoActions.push(this.obj)
        obj := this.undoActions.pop()
        this.obj := obj
    }

    Redo() {
        If !(this.redoActions.length()) {
            msgbox, 4160, , % A_ThisFunc ": Nothing to redo!"
            return
        }
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.redoActions.pop()
        this.obj := obj
    }

    ; input = {object} retrieved by DROP_LOG.GetDrop() containing drop information
    Add(input) {
        If !(input.length()) {
            input.name := "Nothing"
            input.quantity := "N/A"
        }

        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.drops.push(input)
        return true
    }

    StartTrip() {
        If (this.TripActive()) {
            msgbox % A_ThisFunc ": Trip already started!"
            return false
        }
        
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := {}
        obj.drops := {}
        obj.deaths := {}
        obj.tripStart := A_Now
        obj.tripEnd := ""
        this.obj.push(obj)
    }

    EndTrip() {
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.tripEnd := A_Now
    }

    TripActive() {
        obj := this.obj[this.obj.length()]
        If (obj.tripEnd) or !(IsObject(obj))
            return false
        return true
    }

    StartDeath() {
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.deaths.push({"deathStart": A_Now})
    }

    EndDeath() {
        this.redoActions := {}
        this.undoActions.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()].deaths
        obj := obj[obj.length()]
        obj.deathEnd := A_Now
    }

    DeathActive() {
        obj := this.obj[this.obj.length()].deaths
        obj := obj[obj.length()]
        
        If (obj.deathStart) and !(obj.deathEnd)
            return true
    }
}
