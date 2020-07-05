; purpose = retrieves anything required from the osrs wiki
class ClassApiWiki {
    __New() {
        this.url := "https://oldschool.runescape.wiki"
    }
    
    ; converts input to wiki url case
    _ConvertStringToWikiFormat(input) {
        StringLower, output, input
        output := StrReplace(input, A_Space, "_")

        firstChar := SubStr(output, 1, 1)
        If !IsInteger(firstChar) and !InStr(output, "(") ; eg: '3rd age amulet' or 'Bones (Ape Atoll)'
            StringUpper, output, output, T

        return output
    }

    ; input = {string} wiki item quantities eg:
        ; 1
        ; N/A
        ; 3,000
        ; 250–499
        ; 20,000–81,000
        ; ^ <quantity> + ' (noted)'
    ; output = {string} with 'junk' removed eg. 3,000 > 3000
    _ConvertQuantityFromWikiFormat(input) {
        output := input
        If (output = "N/A")
            output := 1
        output := StrReplace(output, ",")
        output := StrReplace(output, " (noted)")

        ; replace any character besides integers with "-" because the wiki uses a weird dash
        ; in their quantitites that glitches out ahk eg. 250-499 becomes 250â€“499
        loop, parse, output
        {
            If A_LoopField is Integer
                LoopField .= A_LoopField
            else
                LoopField .= "-"

        }
        output := LoopField

        return output
    }

    ; input = {string} wiki page name eg: a mob or item
    ; output = valid wiki link to specified target
    GetPageUrl(input) {
        return this.url "/w/" this._ConvertStringToWikiFormat(input)
    }

    ; input = {string} wiki page name eg: a mob or item
    ; output = valid wiki link to specified target
    ; purpose = check for invalid web page "nothing interesting happens"
    GetPageHtml(input) {
        html := DownloadToString(this.GetPageUrl(input))
        If InStr(html, "Nothing interesting happens") and InStr(html, "Weird_gloop_detail.png") {
            msgbox, 4160, , % A_ThisFunc ": Invalid wiki page for '" input "'!`n`nClosing.."
            exitapp
        }
        return html
    }

    /*
        param <input>      = {string} wiki page containing item eg. 'Skeletal wyvern'
        returns            = {string} url to high res image example: https://oldschool.runescape.wiki/images/6/6f/Skeletal_Wyvern.png
    */
    GetMobImageDetailUrl(input) {
        html := this.GetPageHtml(input)

        needle = src="/images/thumb
        loop, parse, html, `n
        {
            If InStr(A_LoopField, needle) {
                html := A_LoopField
                break
            }
        }
        html := SubStr(html, InStr(html, "src=") + 5)
        html := SubStr(html, 1, InStr(html, ".png/") + 3)
        html := StrReplace(html, "/thumb")
        return this.url html
    }

    /*
        param <input>      = {string} wiki page containing item eg. 'Rune axe'
        returns            = {string} url to high res image example: https://oldschool.runescape.wiki/images/thumb/4/45/Ashes_detail.png/100px-Ashes_detail.png
    */
    GetImageDetailUrl(input, size := 50) {
        html := this.GetPageHtml(input)
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)

        images := doc.getElementsByClassName("image")
        If !images.length
            return false

        ; get relative url
        loop % images.length {
            html := images[A_Index-1].innerHtml
            If InStr(html, "_detail")
                break
        }
        html := SubStr(html, InStr(html, "src=") + 5)
        html := SubStr(html, 1, InStr(html, "?") - 1)

        ; set image size
        If InStr(html, "px-") { ; magic logs uses a .gif and doesnt scale
            arr := StrSplit(html, "px-")
            arr[1] := SubStr(arr[1], 1, InStr(arr[1], "/", , 0))    ; example arr[1] = /images/thumb/2/23/Superior_dragon_bones_detail.png/140
            html := arr[1] size "px-" arr[2]                      ; example arr[2] = Superior_dragon_bones_detail.png 
        }
        return this.url html
    }

    /*
        param <input>      = {string} wiki page containing item eg. 'Rune axe'
        returns            = {object} containing urls to
                                    image icon: https://oldschool.runescape.wiki/images/a/a5/Superior_dragon_bones.png?105c4
                                    high detail: https://oldschool.runescape.wiki/images/thumb/4/45/Ashes_detail.png/100px-Ashes_detail.png
    */
    GetImages(input, detailedSize := 50) {
        output := {}

        If InStr(input, "(1)")
            potionDose := 1
        else If InStr(input, "(2)")
            potionDose := 2
        else If InStr(input, "(3)")
            potionDose := 3
        else If InStr(input, "(4)")
            potionDose := 4

        html := this.GetPageHtml(input)
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)

        ; retrieve html information
        output.icon := this._GetIconFromHtmlComObj(doc)
        output.detail := this._GetDetailFromHtmlObj(doc, potionDose)

        return output
    }

    _GetDetailFromHtmlObj(doc, potionDose := "") {
        result := doc.getElementsByClassName("floatleft")
        If !result.length {
            msgbox, 4160, , % A_ThisFunc ": Could not find 'floatleft' class`n`nClosing.."
            exitapp
        }
        If potionDose and (images.length >= potionDose) ; don't apply for eg 'games necklace(2)'
            html := result[potionDose-1].innerHtml
        else
            html := result[0].innerHtml
        return this.url this._GetImageFromInnerHtml(html)
    }

    _GetIconFromHtmlComObj(doc) {
        images := doc.getElementsByClassName("inventory-image")
        If !images.length {
            msgbox, 4160, , % A_ThisFunc ": Could not find 'inventory-image' class`n`nClosing.."
            exitapp
        }
        html := images[0].innerHtml
        return this.url this._GetImageFromInnerHtml(html)
    }

    _GetDetailedItemImageFromHtml(html, size) {
        loop, parse, html, `n
        {
            If InStr(A_LoopField, "og:image") {
                html := A_LoopField
                break
            }
        }
        html := SubStr(html, InStr(html, "content=") + 9)
        html := SubStr(html, 1, InStr(html, "?") - 1)

        ; adjust size
        If size and InStr(html, "px-") {
            arr := StrSplit(html, "px-")
            arr[1] := SubStr(arr[1], 1, InStr(arr[1], "/", , 0))    ; example arr[1] = /images/thumb/2/23/Superior_dragon_bones_detail.png/140
            html := arr[1] size "px-" arr[2]                      ; example arr[2] = Superior_dragon_bones_detail.png 
        }
        return html
    }

    ; images = {array} retrieved by 'doc.getElementsByClassName("image")'
    _GetIconItemImageFromHtmlImageElements(images, input) {
        imgSizeObj := {}
        loop % images.length {
            html := images[A_Index-1].innerHtml "`n"
            widthPlusHeight := this._GetWidthPlusHeightFromInnerHtml(html)
            imgSizeObj[widthPlusHeight] := html
        }
        return imgSizeObj[imgSizeObj.MinIndex()] ; return smallest size image

        loop % images.length {
            imagesString .= images[A_Index-1].innerHtml "`n"
            clipboard := imagesString
        }
        msgbox, 4160, , % A_ThisFunc ": Could not find icon for '" input "'`n`nHtml in clipboard `n`nClosing.."
        exitapp
    }

    _GetWidthPlusHeightFromInnerHtml(html) {
        quoteNeedle = "

        width := html
        width := SubStr(width, InStr(width, "width") + 7)
        width := SubStr(width, 1, InStr(width, quoteNeedle) - 1)

        height := html
        height := SubStr(height, InStr(height, "height") + 8)
        height := SubStr(height, 1, InStr(height, quoteNeedle) - 1)
        
        return width + height
    }

    ; images = {array} retrieved by 'doc.getElementsByClassName("image")'
    _GetDetailedItemImageFromHtmlImageElements(images, input) {
        ; most item images
        loop % images.length {
            html := images[A_Index-1].innerHtml
            If InStr(html, "_detail") ; no input name matching because 'ranarr seed' uses 'Herb seed detail.png'
                return html
        }

        ; 'baby mole' uses high detail image without '_detail' prefix
        arr := StrSplit(input, A_Space)
        inputFirstWord := arr[1]
        loop % images.length {
            html := images[A_Index-1].innerHtml
            If InStr(html, inputFirstWord) and InStr(html, "px-") ; wiki has 'chompy bird' for 'chompy chick'
                return html
        }

        loop % images.length {
            imagesString .= images[A_Index-1].innerHtml "`n"
            clipboard := imagesString
        }
        msgbox, 4160, , % A_ThisFunc ": Could not find icon for '" input "'`n`nHtml in clipboard `n`nClosing.."
        exitapp
    }

    _GetImageFromInnerHtml(input) {
        html := input
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)
        images := doc.getElementsByClassName("image")
        
        lastImageHtml := images[images.length-1].innerHtml ; eg. seed with 5 quantity

        html := lastImageHtml
        html := SubStr(html, InStr(html, "src=") + 5)
        html := SubStr(html, 1, InStr(html, "?") - 1)
        return html
    }

    /*
        param <input>      = {string} wiki page containing drop tables eg. 'Vorkath'
        returns            =  success {object} drop table, example @ "\info\example ClassApiWiki.GetDropTables('Black_demon').json"
                              failure {integer} false
    */
    GetDropTables(input) {
        html := this.GetPageHtml(input)
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)

        this.tables := doc.getElementsByTagName("table")
        If !this.tables.length
            return false

        output := {}
        loop, % this.tables.length {
            table := this.tables[A_Index-1]
            
            ; check if table is a drop table
            If !(table.rows[0].cells.length = 6)
                continue

            title := this._GetTableTitle(html, A_Index-1)
            table := this._GetTable(A_Index-1)

            entry := {}
            entry.title := title
            entry.drops := table
            output.push(entry)
        }
        return output
    }

    /*
        param <whichTable>      = {integer} number of table to retrieve following com format aka the start at 0
        returns                 = {object} drop table 
    */
    _GetTable(whichTable) {
        table := this.tables[whichTable]

        output := {}
        loop % table.rows.length {
            row := table.rows[A_Index-1]
            If (A_Index = 1) ; skip 'header' row containing item, quantity, rarity etc.
                continue

            item := {}
            loop % row.cells.length {
                cell := row.cells[A_Index-1]

                If (A_Index = 1) {
                    ico := SubStr(cell.innerHtml, InStr(cell.innerHtml, "src=") + 5)
                    ico := SubStr(ico, 1, InStr(ico, "?") - 1)
                    item.iconWikiUrl := ico
                }
                If (A_Index = 2) {
                    item.name := cell.innerText
                    item.name := StrReplace(item.name, "(m)") ; members indicator in eg. 'ankou'
                    item.name := StrReplace(item.name, "(f)") ; f2p indicator
                }
                If (A_Index = 3)
                    item.quantity := this._ConvertQuantityFromWikiFormat(cell.innerText)
                If (A_Index = 4)
                    item.rarity := cell.innerText
                If (A_Index = 5)
                    item.price := cell.innerText
                If (A_Index = 6)
                    item.highAlchPrice := cell.innerText
            }
            output.push(item)
       }
       return output
    }

    /*
        param <inputHtml>            = {string} html of wiki page containing drop tables
        param <whichTable>      = {integer} number of table to retrieve following com format aka the start at 0
        returns                 = {string} table title 
    */
    _GetTableTitle(inputHtml, whichTable) {
        table := this.tables[whichTable]
        
        ; retrieve drop table's first item image wiki 'url key' eg. '/images/f/fe/Larran%27s_key_1.png?c6772'
        img := table.rows[1].cells[0].innerHtml
        img := SubStr(img, InStr(img, "src=") + 5)
        img := SubStr(img, 1, InStr(img, """") - 1) ; src=" end quote

        ; get html with drop tables title in it
        loop, parse, inputHtml, `n ; cut off everything after '<item name>.png'
        {
            html .= A_LoopField "`n"
            If InStr(A_LoopField, img) and InStr(A_LoopField, "inventory-image") ; check both because 'abyssal sire' uses Coins_10000.png multiple times
                break
        }
        html := SubStr(html, InStr(html, "mw-headline", false, 0) - 27) ; get last mw-header searching from the end of the string -- 17 is exact

        ; use com to retrieve mw-headeline text
        doc := ComObjCreate("HTMLfile")     ; open ie com object document
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml)                    ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)                     ; add webpage source


        mwHeadlines := doc.getElementsByClassName("mw-headline")
        If !mwHeadlines.length {
            clipboard := html "`n`n-------------------------------inputHtml----------------------------------------" inputHtml
            msgbox, 4160, , % A_ThisFunc ": getElementsByClassName() could not find mw-headline classes in html. (html in clipboard)`n`nClosing.."
            exitapp
        }
        return mwHeadlines[0].innerText
    }
}