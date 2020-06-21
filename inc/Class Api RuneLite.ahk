; retrieve item ids from runelite source code
class ClassApiRunelite {
    __New() {
        this.itemIdUrl := "https://raw.githubusercontent.com/runelite/runelite/master/runelite-api/src/main/java/net/runelite/api/ItemID.java"
        this.apiMainUrl := "https://static.runelite.net/api/http-service/"

        If !(FileExist(PATH_ITEM_IDS))
            this._DownloadItemIdFile()

        this._LoadItemIdFile()
    }

    GetImgUrl(itemId) {
        If !(this.apiUrl)
            this.apiUrl := this._GetApiUrl()

        return this.apiUrl "/cache/item/" itemId "/image"
    }

    ; get current version api url eg. 'HTTPS://api.runelite.net/runelite-1.6.19'
    _GetApiUrl() {
        html := DownloadToString(this.apiMainUrl)

        loop, parse, html, `n
            If (InStr(A_LoopField, "api.runelite.net"))
                return A_LoopField
    }

    ; input = {string} item name eg. 'Rune axe'
    ; output = false or item id if found
    GetId(input) {
        ; adjust input to runelite format
        item := this._EncodeItem(input)

        output := this.obj[item]
        If !(output) { ; try searching again after downloading new version
            this._DownloadItemIdFile()
            this._LoadItemIdFile()
            output := this.obj[item]
            If (output = "") { ; dwarf remains = 0
                msgbox, 4160, , % A_ThisFunc ": Could not find item id for '" input "' `n`nClosing.."
                exitapp
            }
        }
        return output
    }

    ; input = {string} item name eg. 'Rune axe'
    ; output = converted item name to runelite item id's file naming scheme eg. RUNE_AXE
    _EncodeItem(input) {
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

    _LoadItemIdFile() {
        this.obj := json.load(FileRead(PATH_ITEM_IDS))
    }

    _DownloadItemIdFile() {
        input := DownloadToString(this.itemIdUrl)

        obj := {}

        loop, parse, input, `n
        {
            If !(InStr(A_LoopField, "="))
                Continue
            item := SubStr(A_LoopField, InStr(A_Loopfield, "public static final int") + 24)
            item := SubStr(item, 1, InStr(item, "=") - 2)
            
            id := SubStr(A_LoopField, InStr(A_Loopfield, "=") + 2)
            id := RTrim(id, ";")

            ; obj.push({item: item, id: id})
            obj[item] := id
        }
        FileDelete, % PATH_ITEM_IDS
        FileAppend, % json.dump(obj,,2), % PATH_ITEM_IDS
    }
}