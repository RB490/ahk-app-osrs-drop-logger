Class ClassApiOSRSBox {
    __Call(caller) {
        if caller in % "GetMobs"
            this._Load()
    }

    mobs[] {
        get {
            this._Load()
            return this.obj.mobs
        }
    }

    drops[] {
        get {
            this._Load()
            return this.obj.drops
        }
    }

    _Load() {
        hrsOld := GetFileAgeHours(PATH_OSRSBOX_JSON)
        If !FileExist(PATH_OSRSBOX_JSON) or (hrsOld > 168) or ((A_DDDD = "Friday") and hrsOld > 25)
            this._Retrieve()
        
        this.obj := json.load(FileRead(PATH_OSRSBOX_JSON))

        this.loaded := true
    }

    _Retrieve() {
        P.Get(A_ThisFunc, "Retrieving database")

        urlMobs := "https://www.osrsbox.com/osrsbox-db/monsters-complete.json"
        urlMobTitles := "https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/data/wiki/page-titles-monsters.json"
        objMobs := this._GetObjFromJsonUrl(urlMobs)

        ; retrieve items-that-are-in-drop-tables list
        drops := {}
        loop % objMobs.length() {
            mob := objMobs[A_Index]
            If !mob.drops.length()
                Continue
            loop % mob.drops.length() {
                drop := mob.drops[A_Index]
                drops[drop.name] := drop.id
            }
        }

        output := {}
        output.mobs := this._GetObjFromJsonUrl(urlMobTitles)
        output.drops := drops

        FileDelete, % PATH_OSRSBOX_JSON
        FileAppend, % json.dump(output,,2), % PATH_OSRSBOX_JSON

        P.Destroy()
    }

    _GetObjFromJsonUrl(url) {
        obj := json.load(DownloadToString(url))
        If !IsObject(obj)
            Msg("Error", A_ThisFunc ": Could not retrieve required file")
        return obj
    }
}