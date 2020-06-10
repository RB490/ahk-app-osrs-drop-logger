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
        output := this._MergeDuplicateTables(output)
        ; output := this._MergeDuplicateDrops(output)
        return output
    }

    /*
    _MergeDuplicateDrops
        param <input>           = {object} drop tables object from GetDroptables
        returns                 = {object} with duplicate drops merged eg. 2x '1 ashes'
    */
    _MergeDuplicateDrops(input) {
        input := input.clone()
        output := {}

        loop % input.length() { ; go through every drop table
            outputTable := {}
            table := input.pop() ; grab a table

            loop % table.tableDrops.length() { ; go through every item in the drop table
                item := table.tableDrops.pop() ; grab item
                isDuplicate := this._HasItem(outputTable, item)
                If !(isDuplicate)
                    outputTable.push(item)
                else
                    msgbox % "is duplicate: " item.itemName
            }

            entry := {}
            entry.tableTitle := table.tableTitle
            entry.tableDrops := outputTable
            output.push(entry)
        }
        return output
    }

    /*
    _HasItem
        param <table>        = {object} a single drop table
        param <item>         = {object} item object from a drop table
        returns              = {bool} true if 'item' was found in 'table'
    */
    _HasItem(table, item) {
        table := table.clone()

        loop % table.length() {
            If (table[A_Index].itemName = item.itemName) and (table[A_Index].itemQuantity = item.itemQuantity)
                return true
        }
        return false
    }

    /*
    _MergeDuplicateTables
        param <input>           = {object} drop table object from GetDroptables
        returns                 = {object} with duplicate drop tables merged eg. for 'black demon'
    */
    _MergeDuplicateTables(input) {
        input := input.clone()
        output := {}

        loop % input.length() {
            obj := input.pop()
            isDuplicate := this._HasTable(output, obj.tableTitle)
            If (isDuplicate)
                output[isDuplicate].tableDrops.push(obj.tableDrops)
            else
                output.push(obj)
        }
        return output
    }

    /*
    _HasTable
        param <obj>             = {object} drop table object from GetDroptables
        param <tableTitle>      = {string} drop table title to be searched
        returns                 = {bool} true if 'tableTitle' was found in 'obj'
    */
    _HasTable(obj, tableTitle) {      
        For table in obj {
            If (obj[table].tableTitle = tableTitle)
                return table
        }
        return false
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