; purpose = retrieves anything required from the osrs wiki
class ClassApiWiki {
    __New() {
        this.url := "https://oldschool.runescape.wiki"
        this.img := new this.ClassImages(this)
        this.table := new this.ClassDropTables(this)
    }

    GetPageUrl(pageName, useTitleCase := false) {
        return this.url "/w/" this._GetPageNameInWikiFormat(pageName, useTitleCase)
    }

    GetPageHtml(pageName) {
        html := DownloadToString(this.GetPageUrl(pageName)) ; 'A_doubt'

        If this._IsErrorPage(html) ; retry with title case format: 'A_Doubt'
            html := DownloadToString(this.GetPageUrl(pageName, "useTitleCase"))

        If this._IsErrorPage(html) {
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

    _IsErrorPage(html) {
        If InStr(html, "Nothing interesting happens") and InStr(html, "Weird_gloop_detail.png")
            return true
    }

    _GetPageNameInWikiFormat(pageName, useTitleCase := false) { ; eg. 'Rune Axe' becomes 'Rune_axe'
        If (useTitleCase) {
            StringUpper, output, output, T
            output := StrReplace(pageName, A_Space, "_")
            return output
        }
        StringLower, output, pageName
        output := StrReplace(pageName, A_Space, "_")

        firstChar := SubStr(output, 1, 1)
        If !IsInteger(firstChar) and !InStr(output, "(") ; eg: '3rd age amulet' or 'Bones (Ape Atoll)'
            StringUpper, output, output, T

        return output
    }

    _GetDocElementsBy(doc, method, searchTerm) {
        switch method {
            case "Tag": elements := doc.getElementsByTagName(searchTerm)
            case "Class": elements := doc.getElementsByClassName(searchTerm)
            case "Name": elements := doc.getElementsByName(searchTerm)
            default: {
                msgbox, 4160, , % A_ThisFunc ": Invalid method '" method "' `n`nClosing.."
                exitapp
            }
        }
        If !elements.length {
            msgbox, 4160, , % A_ThisFunc ": Could not find any '" searchTerm "' elements `n`nClosing.."
            exitapp
        }
        return elements
    }

    Class ClassDropTables {
        __New(parentInstance) {
            this.parent := parentInstance
        }

        GetDroptable(pageName) {
            this.pageName := pageName
            this.html := this.parent.GetPageHtml(pageName)
            this.doc := this.parent.GetPageDoc(this.html)
            If !this._PageContainsTableTitles() ; otherwise invalid, eg: https://oldschool.runescape.wiki/w/Animated_steel_armour_(Tarn%27s_Lair)
                return false
            this.tables := this._GetDropTables(this.html)
            If !this.tables.length
                return false
            output := {}
            loop % this.tables.length {
                tableHtmlIndex := A_Index-1
                If !(this.tables[tableHtmlIndex].rows[0].cells.Length = 6)
                    continue
                table := {}
                table.title := this._GetTableTitle(tableHtmlIndex)
                table.drops := this._GetTableDrops(tableHtmlIndex)
                output.push(table)
            }
            return output
        }

        _GetTableDrops(tableHtmlIndex) {
            output := {}
            table := this.tables[tableHtmlIndex]
            loop % table.rows.length {
                row := table.rows[A_Index-1]
                If (A_Index = 1) ; skip 'header' row containing item, quantity, rarity etc.
                    continue

                item := {}
                loop % row.cells.length {
                    cell := row.cells[A_Index-1]

                    switch A_Index {
                        case 1: {
                            ico := SubStr(cell.innerHtml, InStr(cell.innerHtml, "src=") + 5)
                            ico := SubStr(ico, 1, InStr(ico, "?") - 1)
                            item.iconWikiUrl := ico
                        }
                        case 2: {
                            item.name := cell.innerText
                            item.name := StrReplace(item.name, "(m)") ; members indicator in eg. 'ankou'
                            item.name := StrReplace(item.name, "(f)") ; f2p indicator
                        }
                        case 3: item.quantity := this._GetQuantityFromWikiFormat(cell.innerText)
                        case 4: item.rarity := cell.innerText
                        case 5: item.price := cell.innerText
                        case 6: item.highAlchPrice := cell.innerText
                    }
                }
                output.push(item)
            }
            return output
        }

        _GetTableTitle(tableHtmlIndex) {
            table := this.tables[tableHtmlIndex]
            
            ; retrieve drop table's first item image wiki 'url key' eg. '/images/f/fe/Larran%27s_key_1.png?c6772'
            img := table.rows[1].cells[0].innerHtml
            img := SubStr(img, InStr(img, "src=") + 5)
            img := SubStr(img, 1, InStr(img, """") - 1) ; src=" end quote

            ; get html with drop tables title in it
            loop, parse, % this.html, `n ; cut off everything after '<item name>.png'
            {
                html .= A_LoopField "`n"
                If InStr(A_LoopField, img) and InStr(A_LoopField, "inventory-image") ; check both because 'abyssal sire' uses Coins_10000.png multiple times
                    break
            }
            html := SubStr(html, InStr(html, "mw-headline", false, 0) - 27) ; get last mw-header searching from the end of the string -- 17 is exact

            ; use com to retrieve mw-headeline text
            doc := this.parent.GetPageDoc(html)
            mwHeadlines := this.parent._GetDocElementsBy(doc, "class", "mw-headline")
            return mwHeadlines[0].innerText
        }

        _GetDropTables(html) {
            tables := this.parent._GetDocElementsBy(this.doc, "tag", "table")
            loop % tables.length {
                firstRowLength := tables[A_Index-1].rows[0].cells.Length
                If (firstRowLength = 6)
                    return tables
            }
            return false
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

        _PageContainsTableTitles() {
            elements := this.doc.getElementsByClassName("mw-headline")
            If elements.length
                return true
        }
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

                If (caller = "GetItemImages") {
                    this.potionDose := this._GetPotionDose(pageName)
                    If (this.potionDose)
                        this.htmlPotionDose := this.potionDose - 1 ; html arrays start at 0
                    else
                        this.htmlPotionDose := 0
                }
            }
        }

        GetMobImage() { ; not scaling in output url as not every mob has a scalable 'thumb' image
            elements := this.parent._GetDocElementsBy(this.doc, "class", "infobox-full-width-content") ; infobox-image

            If (elements.length = 1)
                return this.parent.url "/" this._getImageFromInnerHtml(elements[0].innerHtml)

            ; if infobox has multiple images eg. 'Arianwyn' or 'Glough'
            loop % elements.length {
                images := elements[A_Index-1].GetElementsByClassName("image")
                If images.length {
                    innerHtml := images[0].innerHtml
                    If InStr(innerHtml, "srcset=") ; only the first image in mob infoboxes seems to have this property
                        return this.parent.url "/" this._getImageFromInnerHtml(innerHtml)
                }
            }
            
            msgbox, 4160, , % A_ThisFunc ": Could not find image for '" this.pageName "' `n`nClosing.."
            exitapp
        }

        GetItemImages() {
            output := {}
            output.icon := this._GetItemIcon() ; https://oldschool.runescape.wiki/images/a/a5/Superior_dragon_bones.png?105c4
            output.detail := this._GetItemDetailed() ; https://oldschool.runescape.wiki/images/thumb/4/45/Ashes_detail.png/100px-Ashes_detail.png
            return output
        }

        _GetItemIcon() {
            ; get (last eg. 5 seeds) item html name from infobox
            elements := this.parent._GetDocElementsBy(this.doc, "class", "inventory-image")
            infoImages := elements[0].getElementsByClassName("image")
            html := infoImages[infoImages.length-1].innerHtml
            If !this.potionDose
                return this.parent.url "/" this._getImageFromInnerHtml(html)

            ; get item html name
            htmlAlt := this._getAltFromInnerHtml(html)
            htmlAlt := StrReplace(htmlAlt, "(1)", "(" this.potionDose ")")
            
            ; return correct image in image list 
            images := this.parent._GetDocElementsBy(this.doc, "class", "image")
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
            elements := this.parent._GetDocElementsBy(this.doc, "class", "floatleft")
            return this.parent.url "/" this._getImageFromInnerHtml(elements[this.htmlPotionDose].innerHtml)
        }

        _GetPotionDose(pageName) {
            potionDose := 0
            elements := this.parent._GetDocElementsBy(this.doc, "class", "floatleft")
            If (elements.length < 4) ; potions will have 4 images. 'Games necklace (2)' has 1
                return potionDose

            potionDose := InStr(pageName, "(1)") ? 1 : potionDose
            potionDose := InStr(pageName, "(2)") ? 2 : potionDose
            potionDose := InStr(pageName, "(3)") ? 3 : potionDose
            potionDose := InStr(pageName, "(4)") ? 4 : potionDose
            return potionDose
        }

        _getAltFromInnerHtml(innerHtml) {
            html := innerHtml
            html := SubStr(html, InStr(html, "alt=") + 5)
            html := SubStr(html, 1, InStr(html, """") - 1)
            return html
        }

        _getImageFromInnerHtml(innerHtml) {
            html := innerHtml
            imgNeedleStart = src="/images
            html := SubStr(html, InStr(html, imgNeedleStart) + 6)
            html := SubStr(html, 1, InStr(html, "?") - 1)
            return html
        }
    }
}