class ClassApiWiki {
    __New() {
        this.url := "https://oldschool.runescape.wiki"
    }
    
    ; converts input to wiki url case
    _EncodeText(input) {
        StringLower, output, input
        output := StrReplace(input, A_Space, "_")
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
    _DecodeQuantity(input) {
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

    /*
        param <input>      = {string} wiki page containing item eg. 'Skeletal wyvern'
        returns            = {string} url to high res image example: https://oldschool.runescape.wiki/images/6/6f/Skeletal_Wyvern.png
    */
    GetMobUrl(input) {
        input := this._EncodeText(input)

        html := DownloadToString(this.url "/w/" input)

        needle = src="/images/thumb
        loop, parse, html, `n
        {
            If (InStr(A_LoopField, needle)) {
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
    GetImageUrl(input) {
        input := this._EncodeText(input)
        html := DownloadToString(this.url "/w/" input)

        needleThumb = src="/images/thumb
        needleDetail := input "_detail"

        ; find line containing relative url to our image
        loop, parse, html, `n
        {
            If (InStr(A_LoopField, needleThumb)) and (InStr(A_LoopField, needleDetail)) {
                html := A_LoopField
                break
            }
        }

        ; parse html to retrieve relative image url
        html := SubStr(html, InStr(html, "src=") + 5)
        html := SubStr(html, 1, InStr(html, "?") - 1)

        ; replace xxxpx eg. 800px with default size
        ; current example: /images/thumb/2/20/Black_sword_detail.png/100px-Black_sword_detail.png
        pixels := SubStr(html, InStr(html, ".png/") + 5)
        pixels := SubStr(pixels, 1, InStr(pixels, "px-") - 1)
        html := StrReplace(html, pixels, 100)

        output := baseUrl html
        return output
    }

    /*
        param <input>      = {string} wiki page containing drop tables eg. 'Vorkath'
        returns            =  success {object} drop table, example @ "\info\example ClassApiWiki.GetDropTables('Black_demon').json"
                              failure {integer} false
    */
    GetDropTables(input) {
        input := this._EncodeText(input)
        html := DownloadToString(this.url "/w/" input)
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)

        this.tables := doc.getElementsByTagName("table")
        If !(this.tables.length)
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
                
                If (A_Index = 1)
                    item.iconHtml := cell.innerHtml
                If (A_Index = 2)
                    item.name := cell.innerText
                If (A_Index = 3)
                    item.quantity := this._DecodeQuantity(cell.innerText)
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
        param <html>            = {string} html of wiki page containing drop tables
        param <whichTable>      = {integer} number of table to retrieve following com format aka the start at 0
        returns                 = {string} table title 
    */
    _GetTableTitle(html, whichTable) {
        table := this.tables[whichTable]
        
        ; retrieve drop table's first item image wiki 'url key' eg. '/images/f/fe/Larran%27s_key_1.png?c6772'
        img := table.rows[1].cells[0].innerHtml
        img := SubStr(img, InStr(img, "src=") + 5)
        img := SubStr(img, 1, InStr(img, """") - 1) ; src=" end quote
        
        ; get html with drop tables title in it
        html := SubStr(html, 1, InStr(html, img)) ; cut off everything beyond '<item name>.png'
        html := SubStr(html, InStr(html, "mw-headline", false, 0) - 27) ; get latest mw-header searching from the end of the string -- 17 is exact

        ; use com to retrieve mw-headeline text
        doc := ComObjCreate("HTMLfile")     ; open ie com object document
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml)                    ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)                     ; add webpage source
        return doc.getElementsByClassName("mw-headline")[0].innerText
    }
}