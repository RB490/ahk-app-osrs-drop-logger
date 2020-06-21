Class ClassApiRunelite {
    __New() {
        this.apiHubUrl := "https://static.runelite.net/api/http-service/"
        this.apiUrl := this._GetApiUrl()

        this._GetJson()
        this._SetJson()
    }

    GetItemId(itemString) {
        return this.obj[itemString].id
    }

    GetItemImgUrl(itemString) {
        return this.apiUrl "/cache/item/" this.GetItemId(itemString) "/image"
    }

    GetItemPrice(itemString) {
        return this.obj[itemString].price
    }

    ; get current version api url eg. 'HTTPS://api.runelite.net/runelite-1.6.19'
    _GetApiUrl() {
        html := DownloadToString(this.apiHubUrl)

        loop, parse, html, `n
            If (InStr(A_LoopField, "api.runelite.net"))
                return A_LoopField
    }

    _GetJson() {
        ; only refresh data a few times per day
        If (FileExist(PATH_RUNELITE_JSON)) {
            FileGetTime, OutputVar , % PATH_RUNELITE_JSON, C
            hoursOld := A_Now
            EnvSub, hoursOld, OutputVar, Hours
            If (hoursOld < 6)
                return
        }
        
        input := DownloadToString(this.apiUrl "/item/prices")
        obj := json.load(input)

        ; adjust format
        output := {}
        loop % obj.length() {
            item := obj[A_Index]
            output[item.name] := obj[A_Index]
        }

        FileDelete % PATH_RUNELITE_JSON
        FileAppend, % json.dump(output,,2), % PATH_RUNELITE_JSON
    }

    _SetJson() {
        this.obj := json.load(FileRead(PATH_RUNELITE_JSON))
    }
}