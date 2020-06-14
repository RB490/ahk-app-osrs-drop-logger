class class_dropLog {
    Debug() {
        this.Load("my file")

        this.StartTrip()

        ; add drop
        dropObj := dropTable.GetDrop(3)
        dropObj.Delete("itemHighAlch")
        dropObj.Delete("itemImage")
        dropObj.Delete("itemPrice")
        dropObj.Delete("itemRarity")
        dropLog.Add(dropObj)

        this.StartDeath()

        this._DeathActive()
        ; this.EndDeath()

        ; this.StartDeath()
        ; this.EndDeath()

        

        this.EndTrip()

        msgbox end of meme
    }
    
    ; input = {string} path to existing drop log file
    ; purpose = create drop log object
    Load(input) {
        this.obj := {}
        this.changes := {}
        this.undoneChanges := {}
    }

    Save() {

    }

    Undo() {
        If !(this.changes.length()) {
            msgbox, 4160, , % A_ThisFunc ": Nothing to undo!"
            return
        }
        this.undoneChanges.push(this.obj)
        obj := this.changes.pop()
        this.obj := obj
    }

    Redo() {
        If !(this.undoneChanges.length()) {
            msgbox, 4160, , % A_ThisFunc ": Nothing to redo!"
            return
        }
        obj := this.undoneChanges.pop()
        this.obj := obj
    }

    ; input = {object} retrieved by dropLog.GetDrop() containing drop information
    Add(input) {
        If !(this._tripActive()) {
            msgbox % A_ThisFunc ": No trip started!"
            return
        }
        this.changes.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.drops.push(input)
    }

    StartTrip() {
        obj := {}
        obj.drops := {}
        obj.deaths := {}
        obj.tripStart := A_Now
        obj.tripEnd := ""
        this.obj.push(obj)

        this.changes.push(ObjFullyClone(this.obj))
    }

    EndTrip() {
        this.changes.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.tripEnd := A_Now
    }

    _tripActive() {
        obj := this.obj[this.obj.length()]
        If (obj.tripEnd)
            return false
        return true
    }

    StartDeath() {
        this.changes.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()]
        obj.deaths.push({"deathStart": A_Now})
    }

    EndDeath() {
        this.changes.push(ObjFullyClone(this.obj))
        
        obj := this.obj[this.obj.length()].deaths
        obj := obj[obj.length()]
        obj.deathEnd := A_Now
    }

    _DeathActive() {
        obj := this.obj[this.obj.length()].deaths
        obj := obj[obj.length()]
        If (obj.deathStart)
            return true
    }
}