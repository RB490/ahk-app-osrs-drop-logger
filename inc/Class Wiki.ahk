class class_wiki {
    __New() {
        this.url := "https://oldschool.runescape.wiki"
    }

    /*
    GetDroptables
        param <input>      = {string} context sensitive wiki page containing drop tables eg. 'Vorkath'
        returns            = {object} drop table 
    */
    GetDroptables(input) {
        html := DownloadToString(this.url "/w/" input)
        doc := ComObjCreate("HTMLfile")
        vHtml = <meta http-equiv="X-UA-Compatible" content="IE=edge">
        doc.write(vHtml) ; enable getElementsByClassName https://autohotkey.com/boards/viewtopic.php?f=5&t=31907
        doc.write(html)

        this.tables := doc.getElementsByTagName("table")

        output := {}
        loop, % this.tables.length {
            table := this.tables[A_Index-1]
            
            ; check if table is a drop table
            If !(table.rows[0].cells.length = 6)
                continue

            title := this._GetTableTitle(html, A_Index-1)
            table := this._GetTable(A_Index-1)

            entry := {}
            entry.tableTitle := title
            entry.tableDrops := table
            output.push(entry)
        }
        return output
    }

    /*
    _GetTable
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
                    item.itemImage := cell.innerHtml
                If (A_Index = 2)
                    item.itemName := cell.innerText
                If (A_Index = 3)
                    item.itemQuantity := cell.innerText
                If (A_Index = 4)
                    item.itemRarity := cell.innerText
                If (A_Index = 5)
                    item.itemPrice := cell.innerText
                If (A_Index = 6)
                    item.itemHighAlch := cell.innerText
            }
            output.push(item)
       }
       return output
    }

    /*
    _GetTableTitle
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