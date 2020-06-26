; purpose = retrieves anything required from runelite
Class ClassApiRunelite {
    __New() {
        this.apiHubUrl := "https://static.runelite.net/api/http-service/"
        this.apiUrl := this._GetApiUrl()
        this.idUrl := "https://raw.githubusercontent.com/runelite/runelite/master/runelite-api/src/main/java/net/runelite/api/ItemID.java"

        this._GetJson()
        this._SetJson()
    }

    GetItemId(itemString) {
        return this.obj[this._getRuneliteFormat(itemString)].id
    }

    GetItemPrice(itemString) {
        return this.obj[this._getRuneliteFormat(itemString)].price
    }

    GetItemImgUrl(itemString) {
        return this.apiUrl "/cache/item/" this.GetItemId(itemString) "/image"
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
        
        input := DownloadToString(this.apiUrl "/item/prices") ; this.apiUrl "/item/prices"
        obj := json.load(input)
        If !IsObject(obj) or obj.error {
            msgbox, 4160, , % A_ThisFunc ": Failed to reach RuneLite API`n`nCheck: " PROJECT_WEBSITE
            return
        }

        ; adjust format
        output := {}
        loop % obj.length() {
            item := obj[A_Index]
            output[this._getRuneliteFormat(item.name)] := obj[A_Index]
        }

        ; add untradeable items
        input := DownloadToString(this.idUrl)
        loop, parse, input, `n
        {
            If InStr(A_LoopField, "public static final int") {
                name := SubStr(A_LoopField, InStr(A_LoopField, "public static final int") + 24)
                name := SubStr(name, 1, InStr(name, "=") - 2)
                
                id := SubStr(A_LoopField, InStr(A_LoopField, "=") + 2)
                id := SubStr(id, 1, InStr(id, ";") - 1)

                If !(output.HasKey(name))
                    output[name] := {id: id}
            }
        }

        FileDelete % PATH_RUNELITE_JSON
        FileAppend, % json.dump(output,,2), % PATH_RUNELITE_JSON
    }

    _SetJson() {
        this.obj := json.load(FileRead(PATH_RUNELITE_JSON))
    }

    ; input = {string} item name eg. 'Rune axe'
    ; output = converted item name to runelite item id's file naming scheme eg. RUNE_AXE
    _getRuneliteFormat(input) {
        output := input

        ; remove members/f2p markings
        output := StrReplace(output, "(m)")
        output := StrReplace(output, "(f)")

        ; remove '-' eg. Zul-andra teleport
        output := StrReplace(output, "-")

        ; remove '+' eg. Antidote++(4)
        output := StrReplace(output, "+")

        ; remove brackets
        output := StrReplace(output, "(", "") ; eg. defence potion(3)
        output := StrReplace(output, ")", "")

        ; remove this character '
        output := StrReplace(output, "'")

        ; remove space infront of last character if integer for eg. super strength (3)
        lastChar := SubStr(output, StrLen(output))
        If lastChar is Integer
            output := StrReplace(output, A_Space lastChar, lastChar)

        ; add '_' if first character is integer
        firstChar := SubStr(output, 1, 1)
            If firstChar is Integer
                output := "_" output

        ; replace spaces with underscores
        output := StrReplace(output, A_Space, "_")
        StringUpper, output, output
        return output
    }
}