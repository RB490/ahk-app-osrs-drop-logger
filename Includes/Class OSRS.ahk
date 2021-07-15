
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
        ; P.Get(A_ThisFunc, "Loading mob database", A_Space, A_Space)

        ; MOBS -------------------------------------------------------------------------------------

        ; read database from disk
        input := FileRead(PATH_DATABASE_MOBS)
        obj := json.load(input)

        ; check database creation time
        If FileExist(PATH_DATABASE_MOBS) {
            FileGetTime, OutputVar , % PATH_DATABASE_MOBS, C
            hoursOld := A_Now
            EnvSub, hoursOld, OutputVar, Hours
        }

        ; update if database list unavailable or more than x hours old
        If !IsObject(obj)
            this._Update()
        obj := json.load(FileRead(PATH_DATABASE_MOBS))

        ; if necessary, update database in the background if we already have a database available
        If (hoursOld > 168) or (A_DDDD = "Friday") ; friday is a day after osrs gets updated
            SetTimer, updateMobDb, -60000

        ; check if the database is now available
        If !IsObject(obj)
            Msg("Error", A_ThisFunc, "No mob database available")
        
        this.mobs := obj

        ; ITEMS ------------------------------------------------------------------------------------
        obj := json.load(FileRead(PATH_DATABASE_MOBS_DROP_LIST))
        If (obj.length() < 50)
            Msg("Error", A_ThisFunc, "Drop list unavailable at:`n`n" PATH_DATABASE_MOBS_DROP_LIST)
        this.items := obj

        P.Destroy()
    }

    ; return object with unique drops itemId:itemName
    GetItems() {
        return this.items
    }

    ; return object with mobName:mobId
    GetMobs() {
        obj := this.mobs
        output := []

        for mobId in obj
            output[mobId] := obj[mobId].name

        return output
    }

    GetMobID(mobName) {
        obj := this.mobs
        for mob in obj
            If obj[mob].name = mobName
                return mob
        
        ; didnt find id
        Msg("Error", A_ThisFunc, "Unable to find mob id for: " mobName)
    }

    GetItemID(itemName) {
        for id, item in this.items
            If (item = itemName)
                return id

        ; didnt find id
        Msg("Error", A_ThisFunc, "Unable to find item id for: " itemName)
    }

    GetWikiUrlForMob(mob) {
        obj := this._GetMobObj(mob)
        return obj.wiki_url
    }

    GetDropTable(mob) {
        obj := this._GetMobObj(mob)
        return obj.drops
    }

    _Update(silent := false) {
        If !silent
            P.Get(A_ThisFunc, "Updating mob database", A_Space, A_Space) ; title-text1-bar1-bar1text
        
        ; update files
        this._UpdateMobsDatabase()
        this._UpdateDropListDatabase()

        P.Destroy()
        If silent ; inform user through traytrip
            TrayTip, % APP_NAME, Updated monster database!`nRestart to take effect, 5, 17
    }
    _UpdateMobsDatabase() {
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
        output := []
        addedMobNames := [] ; keep track of added mob names so we can ignore duplicates
        for mob_id in input {
            mob := input[mob_id]
            
            ; skip mobs without a droptable
            If !mob.drops.count()
                Continue
            ; skip mobs that we already added
            If addedMobNames.HasKey(mob.wiki_name)
                Continue

            output[mob_id] := [] ; add this mob to our new output object
            output[mob_id].name := mob.wiki_name ; using wiki name to include different versions of the same mob
            output[mob_id].last_updated := mob.last_updated
            addedMobNames[mob.wiki_name] := ""
            ; output[mob_id].id := mob.id
            ; output[mob_id].wiki_name := mob.wiki_name
            
            P.B1()
            P.T2(mob.wiki_name A_Space "(ID: " mob.id ")")

            ; msgbox % json.dump(output,,2)
            ; sleep 1000
        }

        ; save to disk
        FileDelete, % PATH_DATABASE_MOBS
        FileAppend, % json.dump(output,,2), % PATH_DATABASE_MOBS
        return output
    }

    _UpdateDropListDatabase() {
        output := {}
        mobList := this.GetMobs()

        for i, mob in mobList {
            dropList := this.GetDropTable(mob)
            for i, drop in dropList
                output[drop.id] := drop.name
        }

        ; save to disk
        FileDelete, % PATH_DATABASE_MOBS_DROP_LIST
        FileAppend, % json.dump(output,,2), % PATH_DATABASE_MOBS_DROP_LIST

        return output
    }

    ; input [mob] either a mob name or mobID
    _GetMobObj(mob) {
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

        P.Destroy()
        return obj
    }
}