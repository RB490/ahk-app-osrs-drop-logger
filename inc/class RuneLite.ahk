; retrieve item ids from runelite source code
class class_runeLite {
    __New() {
        this.itemIdUrl := "https://raw.githubusercontent.com/runelite/runelite/master/runelite-api/src/main/java/net/runelite/api/ItemID.java"
        this.apiMainUrl := "https://static.runelite.net/api/http-service/"
        this.apiUrl := this._GetApiUrl()

        If !(FileExist(g_itemIdsPath))
            this._DownloadItemIdFile()

        this._LoadItemIdFile()
    }

    GetImgUrl(itemId) {
        return this.apiUrl "/cache/item/" itemId "/image"
    }

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
        this.obj := json.load(FileRead(g_itemIdsPath))
    }

    _DownloadItemIdFile() {
        input := DownloadToString(this.itemIdUrl)

        obj := {}

        loop, parse, input, `n
        {
            If !(InStr(A_LoopField, "="))
                Continue
            itemName := SubStr(A_LoopField, InStr(A_Loopfield, "public static final int") + 24)
            itemName := SubStr(itemName, 1, InStr(itemName, "=") - 2)
            
            itemId := SubStr(A_LoopField, InStr(A_Loopfield, "=") + 2)
            itemId := RTrim(itemId, ";")

            ; obj.push({itemName: itemName, itemId: itemId})
            obj[itemName] := itemId
        }
        FileDelete, % g_itemIdsPath
        FileAppend, % json.dump(obj,,2), % g_itemIdsPath
    }
}