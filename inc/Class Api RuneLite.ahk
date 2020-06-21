Class ClassApiRunelite {
    __New() {
        this.apiHubUrl := "https://static.runelite.net/api/http-service/"
        this.apiUrl := this._GetApiUrl()

        this._GetJson()
        this._SetJson()
    }

    GetItemId(itemString) {
        loop % this.obj.length() {
            item := this.obj[A_Index]
            
            If (item.name = itemString)
                return item.id
        }
    }

    GetItemImgUrl(itemString) {
        itemId := this.GetItemId(itemString)
        return this.apiUrl "/cache/item/" itemId "/image"
    }

    GetItemPrice(itemString) {
        loop % this.obj.length() {
            item := this.obj[A_Index]
            
            If (item.name = itemString)
                return item.id
        }
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
        FileDelete % PATH_RUNELITE_JSON
        FileAppend, % json.dump(obj,,2), % PATH_RUNELITE_JSON
    }

    _SetJson() {
        this.obj := json.load(FileRead(PATH_RUNELITE_JSON))
    }
}