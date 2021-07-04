
/*
 Purpose: Retrieve mob info. Such as last time it was updated on the wiki and the drop table

 Links:
    complete monsters list #1   = https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-complete.json
    complete monsters list #2   = https://github.com/osrsbox/osrsbox-db/blob/master/docs/monsters-complete.json
    specific monsters #1        = https://api.osrsbox.com/monsters/<MONSTER_ID>
    specific monsters #2        = https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-json/<MONSTER_ID>.json
*/

Class ClassDatabaseMobs {
    monstersCompleteUrl := "https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-complete.json"
    monsterSpecificBaseUrl := "https://api.osrsbox.com/monsters"

    __New() {
        ; P.Get(A_ThisFunc, "Loading mob database", A_Space, A_Space)

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
        If !IsObject(obj) or (hoursOld > 168)
            obj := this._Update()
        else
            obj := json.load(FileRead(PATH_DATABASE_MOBS))

        ; check if the database is now available
        If !IsObject(obj)
            Msg("Error", A_ThisFunc, "No mob database available")

        this.obj := obj

        P.Destroy()
    }

    _Update() {
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
        output := []
        addedMobNames := [] ; keep track of added mob names so we can ignore duplicates
        for mob_id in input {
            mob := input[mob_id]
            
            ; skip mobs without a droptable
            If !mob.drops.count()
                Continue
            ; skip mobs that we already added
            If addedMobNames.HasKey(mob.name)
                Continue

            output[mob_id] := [] ; add this mob to our new output object
            output[mob_id].name := mob.name
            output[mob_id].last_updated := mob.last_updated
            addedMobNames[mob.name] := ""
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

        P.Destroy()
        return output
    }

    ; return object with mob names
    GetList() {
        obj := this.obj
        output := []

        for mob in obj
            output[mob] := obj[mob].name

        return output
    }

    GetId(mobName) {
        obj := this.obj
        for mob in obj
            If obj[mob].name = mobName
                return mob
    }

    GetWikiUrl(mob) {
        obj := this._GetMobObj(mob)
        return obj.wiki_url
    }

    GetDropTable(mob) {
        obj := this._GetMobObj(mob)
        return obj.drops
    }

    ; input [mob] either a mob name or mobID
    _GetMobObj(mob) {
        ; get mob id
        If !IsInteger(mob)
            mob := this.GetId(mob)
        id := mob

        ; build file path
        file := DIR_DATABASE_MOBS "\" id ".json"
        
        ; check if we have this mob stored on disk
        input := FileRead(file)
        obj := json.load(input)
        If !IsObject(obj) or (obj.last_updated != this.obj[id].last_updated)
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