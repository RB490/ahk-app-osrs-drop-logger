; example in res\example class_dropTable.json
class class_dropLog {   
    ; output = {string} containing current trip drops
    Get() {
        obj := this.obj[this.obj.length()].drops
        loop % obj.length() {
            kill := A_Index
            loop % obj[A_Index].length()
                drops .= obj[kill][A_Index].itemQuantity " x " obj[kill][A_Index].itemName ", "
            
            drops := RTrim(drops, ", ")
            drops .= "`r `n"
        }
        return drops
    }

    ; input = {string} path to existing drop log file
    ; purpose = create drop log object
    Load(input) {
        this.obj := {}
        this.undoActions := {}
        this.redoActions := {}
    }

    Save() {

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

    ; input = {object} retrieved by dropLog.GetDrop() containing drop information
    Add(input) {
        If !(input.length()) {
            input.itemName := "Nothing"
            input.itemQuantity := "N/A"
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