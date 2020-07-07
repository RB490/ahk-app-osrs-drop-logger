; purpose = retrieves anything required from the osrs wiki
class ClassApiWiki {
    __New() {
        this.url := "https://oldschool.runescape.wiki"
        this.img := new this.ClassImages(this)
    }

    Class ClassImages {
        __New(parentInstance) {
            this.parent := parentInstance
        }

        __Call(caller, pageName) {
            If !InStr(caller, "_") {
                this.pageName := pageName
                this.url := this.parent.GetPageUrl(pageName)
                this.html := this.parent.GetPageHtml(pageName)
                this.doc := this.parent.GetPageDoc(this.html)
                this.potionDose := this._GetPotionDose(pageName)
                If (this.potionDose)
                    this.htmlPotionDose := this.potionDose - 1 ; html arrays start at 0
                else
                    this.htmlPotionDose := 0
            }
        }

        GetMobImage() {
            elements := this._getElementsByClassName("infobox-image")
            return this.parent.url "/" this._getImageFromInnerHtml(elements[0].innerHtml)
        }

        GetItemImages() {
            output := {}
            output.icon := this._GetItemIcon() ; https://oldschool.runescape.wiki/images/a/a5/Superior_dragon_bones.png?105c4
            output.detail := this._GetItemDetailed() ; https://oldschool.runescape.wiki/images/thumb/4/45/Ashes_detail.png/100px-Ashes_detail.png
            return output
        }

        _GetItemIcon() {
            ; get (last eg. 5 seeds) item html name from infobox
            elements := this._getElementsByClassName("inventory-image")
            infoImages := elements[0].getElementsByClassName("image")
            html := infoImages[infoImages.length-1].innerHtml

            If !this.potionDose
                return this.parent.url "/" this._getImageFromInnerHtml(html)

            ; get item html name
            htmlAlt := this._getAltFromInnerHtml(html)
            htmlAlt := StrReplace(htmlAlt, "(1)", "(" this.potionDose ")")
            
            ; return correct image in image list 
            images := this._getElementsByClassName("image")
            loop % images.length {
                loopHtml := images[A_Index-1].innerHtml
                loopAlt := this._getAltFromInnerHtml(loopHtml)
                if (htmlAlt = loopAlt)
                    return this.parent.url "/" this._getImageFromInnerHtml(loopHtml)
            }

            msgbox, 4160, , % A_ThisFunc ": Could not find icon for '" this.pageName "' with potion dose '" this.potionDose "' `n`nClosing.."
            exitapp
        }

        _GetItemDetailed() {
            elements := this._getElementsByClassName("floatleft")
            If (elements.length <= this.htmlPotionDose) {
                msgbox, 4160, , % A_ThisFunc ": Could not find image for '" this.pageName "' with potion dose '" this.potionDose "' `n`nClosing.."
                exitapp
            }
            return this.parent.url "/" this._getImageFromInnerHtml(elements[this.htmlPotionDose].innerHtml)
        }

        _GetPotionDose(pageName) {
            potionDose := 0
            If InStr(pageName, "(1)")
                potionDose := 1
            else If InStr(pageName, "(2)")
                potionDose := 2
            else If InStr(pageName, "(3)")
                potionDose := 3
            else If InStr(pageName, "(4)")
                potionDose := 4
            return potionDose
        }

        _getElementsByClassName(className) {
            elements := this.doc.getElementsByClassName(className)
            If !elements.length {
                msgbox, 4160, , % A_ThisFunc ": Could not find any '" className "' elements `n`nClosing.."
                exitapp
            }
            return elements
        }

        _getAltFromInnerHtml(innerHtml) {
            html := innerHtml
            html := SubStr(html, InStr(html, "alt=") + 5)
            html := SubStr(html, 1, InStr(html, """") - 1)
            return html
        }

        _getImageFromInnerHtml(innerHtml) {
            html := innerHtml
            html := SubStr(html, InStr(html, "src=") + 6)
            html := SubStr(html, 1, InStr(html, "?") - 1)
            return html
        }
    }

    GetPageUrl(pageName) {
        return this.url "/w/" this._GetPageNameInWikiFormat(pageName)
    }

    GetPageHtml(pageName) {
        html := DownloadToString(this.GetPageUrl(pageName))
        If InStr(html, "Nothing interesting happens") and InStr(html, "Weird_gloop_detail.png") {
            msgbox, 4160, , % A_ThisFunc ": Invalid wiki page for '" pageName "'!`n`nClosing.."
            exitapp
        }
        return html
    }

    GetPageDoc(pageHtml) {
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(pageHtml)
        return doc
    }

    /*
        param <pageName>    = {string} wiki page containing drop tables eg. 'Vorkath'
        returns             = success {object} drop table, example @ "\info\example ClassApiWiki.GetDropTables('Black_demon').json"
                              failure {integer} false
    */
    GetDropTables(pageName) {
        html := this.GetPageHtml(pageName)
        doc := this.GetPageDoc(html)

        this.tables := doc.getElementsByTagName("table")
        If !this.tables.length
            return false

        output := {}
        loop, % this.tables.length {
            table := this.tables[A_Index-1]
            
            ; check if table is a drop table
            If !(table.rows[0].cells.length = 6)
                continue

            title := this._GetTableTitleFromPageHtml(html, A_Index-1)
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
                    item.quantity := this._GetQuantityFromWikiFormat(cell.innerText)
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
        param <pageHtml>       = {string} html of wiki page containing drop tables
        param <whichTable>      = {integer} number of table to retrieve following com format aka the start at 0
        returns                 = {string} table title 
    */
    _GetTableTitleFromPageHtml(pageHtml, whichTable) {
        table := this.tables[whichTable]
        
        ; retrieve drop table's first item image wiki 'url key' eg. '/images/f/fe/Larran%27s_key_1.png?c6772'
        img := table.rows[1].cells[0].innerHtml
        img := SubStr(img, InStr(img, "src=") + 5)
        img := SubStr(img, 1, InStr(img, """") - 1) ; src=" end quote

        ; get html with drop tables title in it
        loop, parse, pageHtml, `n ; cut off everything after '<item name>.png'
        {
            html .= A_LoopField "`n"
            If InStr(A_LoopField, img) and InStr(A_LoopField, "inventory-image") ; check both because 'abyssal sire' uses Coins_10000.png multiple times
                break
        }
        html := SubStr(html, InStr(html, "mw-headline", false, 0) - 27) ; get last mw-header searching from the end of the string -- 17 is exact

        ; use com to retrieve mw-headeline text
        doc := this.GetPageDoc(html)
        mwHeadlines := doc.getElementsByClassName("mw-headline")
        If !mwHeadlines.length {
            clipboard := html "`n`n-------------------------------pageHtml----------------------------------------" pageHtml
            msgbox, 4160, , % A_ThisFunc ": getElementsByClassName() could not find mw-headline classes in html. (html in clipboard)`n`nClosing.."
            exitapp
        }
        return mwHeadlines[0].innerText
    }

    ; eg. 'Rune Axe' becomes 'Rune_axe'
    _GetPageNameInWikiFormat(pageName) {
        StringLower, output, pageName
        output := StrReplace(pageName, A_Space, "_")

        firstChar := SubStr(output, 1, 1)
        If !IsInteger(firstChar) and !InStr(output, "(") ; eg: '3rd age amulet' or 'Bones (Ape Atoll)'
            StringUpper, output, output, T

        return output
    }

    /*
        wikiQuantity = {string} wiki item quantities eg:
            1
            N/A
            3,000
            250–499
            20,000–81,000
            ^ <quantity> + ' (noted)'
        output = {integer} with 'junk' removed eg. 3,000 > 3000
    */
    _GetQuantityFromWikiFormat(wikiQuantity) {
        output := wikiQuantity
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
}