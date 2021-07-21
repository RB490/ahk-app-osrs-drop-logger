
/*
 Purpose: Retrieve mob and items info. Such as last time a mob was updated on the wiki or a drop table

 Links:
    complete monsters list #1   = https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-complete.json
    complete monsters list #2   = https://github.com/osrsbox/osrsbox-db/blob/master/docs/monsters-complete.json
    specific monsters #1        = https://api.osrsbox.com/monsters/<MONSTER_ID>
    specific monsters #2        = https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-json/<MONSTER_ID>.json
*/

Class ClassOSRS {
    monstersCompleteUrl := "https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-complete.json"
    monsterSpecificBaseUrl := "https://api.osrsbox.com/monsters"

    ; load json files and update them if necessary
    __New() {
        ; MOBS -------------------------------------------------------------------------------------
        
        ; try to load file from disk
        obj := json.load(FileRead(PATH_DATABASE_MOBS))
        fileAge := A_Now
        fileAge -= obj.lastUpdated, Hours

        ; update the file if neccessary
        If !(obj.lastUpdated) or !(obj.content.count()) {
            output := this._UpdateMobDatabase()
            If output.lastUpdated
                obj := output
            else
                Msg("Info", A_ThisFunc, "Update failed")
        }

        ; verify input
        If !obj.lastUpdated or !obj.content.count()
            Msg("Error", A_ThisFunc, "Data unavailable")

        this.mobs := obj.content

        ; silently update in the background for next restart if already available and requirements are met
        If (fileAge > 168) ; 168 hours = 1 week
            SetTimer, updateMobDb, -60000

        ; ITEMS ------------------------------------------------------------------------------------
        
        ; try to load file from disk
        obj := json.load(FileRead(PATH_DATABASE_ITEMS))
        fileAge := A_Now
        fileAge -= obj.lastUpdated, Hours

        ; update the file if neccessary
        If !(obj.lastUpdated) or !(obj.content.count()) {
            output := this._UpdateItemDatabase()
            If output.lastUpdated
                obj := output
            else
                Msg("Info", A_ThisFunc, "Update failed")
        }

        ; verify input
        If !obj.lastUpdated or !obj.content.count()
            Msg("Error", A_ThisFunc, "Data unavailable")

        this.items := obj.content

        P.Destroy()
    }

    ; returns mob object
    _GetMob(mob) {
        ; get mob id
        If !IsInteger(mob)
            mob := this.GetMobID(mob)
        id := mob


        ; build file path
        file := DIR_DATABASE_MOBS "\" id ".json"
        
        ; check if we have this mob stored on disk
        input := FileRead(file)
        obj := json.load(input)
        If !IsObject(obj) or (obj.last_updated != this.mobs[id].last_updated)
            obj := this._UpdateMob(id)

        ; can't continue if we weren't able to retrieve the mob
        If !IsObject(obj)
            Msg("Error", A_ThisFunc, "Was not able to retrieve mob info. ID: " id)

        return obj
    }

    ; return object with all mobName:mobId
    GetMobs() {
        obj := this.mobs
        output := []

        for mobId in obj
            output[mobId] := obj[mobId].name

        return output
    }

    ; returns mobs ID
    GetMobID(mobName) {
        obj := this.mobs
        for mob in obj
            If obj[mob].name = mobName
                return mob
        
        ; didnt find id
        Msg("Error", A_ThisFunc, "Unable to find mob id for: " mobName)
    }

    ; returns the mobs wiki_url as retrieved by osrsbox.com
    GetMobUrl(mob) {
        return this._GetMob(mob).wiki_url
    }

    ; returns the mobs drop table
    GetMobTable(mob) {
        return this._GetMob(mob).drops
    }

    ; return object with all items that are in a droptable using format: ID:NAME
    GetItems() {
        return this.items
    }

    ; returns item id
    GetItemID(itemName) {
        for id, item in this.items
            If (item = itemName)
                return id

        ; didnt find id
        Msg("Error", A_ThisFunc, "Unable to find item id for: " itemName)
    }

    ; download up-to-date json from osrsbox.com
    _UpdateMobDatabase(silent := false) {
        If !silent
            P.Get(A_ThisFunc, "Updating mob database", A_Space, A_Space) ; title-text1-bar1-bar1text

        ; input := FileRead(A_ScriptDir "\Dev\monsters-complete-1page.txt")
        input := DownloadToString(this.monstersCompleteUrl)

        input := json.load(input), P.B1(input.Count())

        ; check if the input is valid
        If !IsObject(input) {
            Msg("Info", A_ThisFunc, "Unable to update the mob database")
            p.Destroy()
            return
        }

        ; cleanup the obj by only keeping usefull data
        output := {lastUpdated: A_Now, content: {}}
        addedMobNames := [] ; keep track of added mob names so we can ignore duplicates
        for mob_id in input {
            mob := input[mob_id]
            
            ; skip mobs without a droptable
            If !mob.drops.count()
                Continue
            ; skip mobs that we already added
            If addedMobNames.HasKey(mob.wiki_name)
                Continue

            output["content"][mob_id] := [] ; add this mob to our new output object
            output["content"][mob_id].name := mob.wiki_name ; using wiki name to include different versions of the same mob
            output["content"][mob_id].last_updated := mob.last_updated
            addedMobNames[mob.wiki_name] := ""
            ; output["content"][mob_id].id := mob.id
            ; output["content"][mob_id].wiki_name := mob.wiki_name
            
            P.B1()
            P.T2(mob.wiki_name A_Space "(ID: " mob.id ")")

            ; msgbox % json.dump(output,,2)
            ; sleep 1000
        }

        ; save to disk
        FileDelete, % PATH_DATABASE_MOBS
        FileAppend, % json.dump(output,,2), % PATH_DATABASE_MOBS

        ; returning
        P.Destroy()
        If silent ; inform user through traytrip
            TrayTip, % APP_NAME, Updated monster database!`nRestart to take effect, 5, 17
        return output
    }

    ; create up-to-date json using the mob database
    _UpdateItemDatabase() {
        output := {lastUpdated: A_Now, content: {}}
        mobList := this.GetMobs()

        for i, mob in mobList {
            dropList := this.GetMobTable(mob)
            for i, drop in dropList
                output["content"][drop.id] := drop.name
        }

        ; save to disk
        FileDelete, % PATH_DATABASE_ITEMS
        FileAppend, % json.dump(output,,2), % PATH_DATABASE_ITEMS

        return output
    }

    ; download up-to-date json from osrsbox.com
    _UpdateMob(mobID) {
        ; verify input
        If !IsInteger(mobID)
            Msg("Error", A_ThisFunc, "Invalid mob id input " "'"  mobID "'")

        ; inform user
        P.Get(A_ThisFunc, "Updating mob '" mobID "'")

        ; set required variables
        file := DIR_DATABASE_MOBS "\" mobID ".json"
        url := this.monsterSpecificBaseUrl "/" mobID

        ; download api result
        input := DownloadToString(url)
        obj := json.load(input)

        ; verify output
        If !IsObject(obj) {
            Msg("Info", A_ThisFunc, "Was not able to update mod with id: " mobID)
            return
        }

        ; save to disk
        FileDelete, % file
        FileAppend, % json.dump(obj,,2), % file

        ; finish up
        P.Destroy()
        return obj
    }
}