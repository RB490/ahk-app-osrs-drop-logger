; purpose = retrieves anything required from runelite
Class ClassApiRunelite {
    __Call(caller) {
        methodsThatRequireThisObj = GetItemId,GetItemPrice,GetItemImgUrl
        if caller in % methodsThatRequireThisObj
            this.Load()
    }

    apiHubUrl[] {
        get {
            this.Load()
            return this.apiHubUrl
        }
    }

    Load() {
        If this.isLoaded
            return
        
        this.apiHubUrl := "https://static.runelite.net/api/http-service/"
        this.apiUrl := this._GetApiUrl()
        this.idUrl := "https://raw.githubusercontent.com/runelite/runelite/master/runelite-api/src/main/java/net/runelite/api/ItemID.java"

        this._GetJson()
        this._SetJson()

        this.isLoaded := true
    }

    GetItemId(itemString) {
        switch itemString
        {   ; runelite api json corrections - tested with monsters-complete.json from osrsbox
            case "Bandana eyepatch (white)": return 8924 
            case "Bandana eyepatch (red)": return 8925
            case "Bandana eyepatch (blue)": return 8926
            case "Bandana eyepatch (brown)": return 8927
            case "Blamish blue shell (pointed)": return 3361
            case "Blamish blue shell (round)": return 3362
            case "Blamish red shell (round)": return 3357
            case "Blamish red shell (pointed)": return 3358
            case "Blamish myre shell (pointed)": return 3355
            case "Blamish myre shell (round)": return 3356
            case "Blamish ochre shell (round)": return 3359
            case "Blamish ochre shell (pointed)": return 3360
            case "Bronze key (H.A.M.)": return 8867
            case "Iron key (H.A.M.)": return 8869
            case "Silver key (H.A.M.)": return 8868
            case "Steel key (H.A.M.)": return 8866
            case "Bones (Ape Atoll)": return 526
            case "Monkey bones (bearded gorilla)": return 3183
            case "Monkey bones (gorilla)": return 3183
            case "Monkey bones (large zombie)": return 3183
            case "Monkey bones (medium ninja)": return 3183
            case "Monkey bones (small ninja)": return 3183
            case "Monkey bones (small zombie)": return 3183
            case "Crawling hand (item)": return 7975
            case "Crest part (Johnathon)": return 780
            case "Grym leaf (corrupted)": return 23835
            case "Key (The Lost Tribe)": return 275
            case "Map part (Lozar)": return 1537
            case "Paladin's badge (Sir Carl)": return 1489
            case "Paladin's badge (Sir Harry)": return 1490
            case "Paladin's badge (Sir Jerro)": return 1488
            case "Prison key (Troll Stronghold)": return 3135
            case "Raw beef (undead)": return 4287
            case "Raw chicken (undead)": return 4289
            case "Rock (elemental)": return 1480
            case "Swamp toad (item)": return 2150
            case "Teleport crystal (The Gauntlet)": return 23904
            case "Tribal mask (blue)": return 6339
            case "Tribal mask (green)": return 6335
            case "Tribal mask (orange)": return 6337
            case "Weapon frame (corrupted)": return 23834
        }
        id := this.obj[this._getRuneliteFormat(itemString)].id
        If !id {
            msgbox, 4160, , % A_ThisFunc ": Could not retrieve item id for '" itemString "'`n`nClosing.."
            exitapp
            ; FileAppend, % itemString "`n", D:\Downloads\errors_GetItemId.txt
        }
        return id
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
            If InStr(A_LoopField, "api.runelite.net")
                return A_LoopField
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

        ; remove space infront of last character if integer for eg. super strength (3)
        If InStr(output, "(") and InStr(output, ")") {
            lastChar := SubStr(output, StrLen(output))
            If lastChar is Integer
                output := StrReplace(output, A_Space lastChar, lastChar)
        }

        ; remove brackets
        output := StrReplace(output, "(", "") ; eg. defence potion(3)
        output := StrReplace(output, ")", "")

        ; remove this character ' eg. Vet'ion jr.
        output := StrReplace(output, "'")

        ; remove this character ' eg. Vet'ion jr.
        output := StrReplace(output, ".")

        ; add '_' if first character is integer
        firstChar := SubStr(output, 1, 1)
            If firstChar is Integer
                output := "_" output

        ; replace spaces with underscores
        output := StrReplace(output, A_Space, "_")
        StringUpper, output, output
        return output
    }

    _GetJson() {
        ; only refresh data a few times per day
        If FileExist(PATH_RUNELITE_JSON) {
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
        If !input {
            msgbox, 4160, , % A_ThisFunc ": Failed to reach RuneLite API item id's`n`nCheck: " PROJECT_WEBSITE
            return
        }
        loop, parse, input, `n
        {
            If InStr(A_LoopField, "public static final int") {
                name := SubStr(A_LoopField, InStr(A_LoopField, "public static final int") + 24)
                name := SubStr(name, 1, InStr(name, "=") - 2)
                
                id := SubStr(A_LoopField, InStr(A_LoopField, "=") + 2)
                id := SubStr(id, 1, InStr(id, ";") - 1)

                If !output.HasKey(name)
                    output[name] := {id: id}
            }
        }

        FileDelete % PATH_RUNELITE_JSON
        FileAppend, % json.dump(output,,2), % PATH_RUNELITE_JSON
    }

    _SetJson() {
        this.obj := json.load(FileRead(PATH_RUNELITE_JSON))
    }
}