; purpose = modify and retrieve drop tables information
class class_DropTable {
    
    /*
        param <input>       = {string} context sensitive wiki page containing drop tables eg. 'Vorkath'
        purpose             = retrieve a mob's drop table and download drop item images
    */
    GetDrops(input) {
        this.minTableSize := 32 ; tables below this many itemes get merged together. rdt has 33 drops
        
        If !(g_debug)
            SplashTextOn, 300, 75, % A_ScriptName, Retrieving drop table for %input%...
        
        ;;; retrieve drop tables
        ; this.obj := wiki.GetDroptables(input)
        ; FileAppend, % json.dump(this.obj,,2), % A_ScriptDir "\Debug_DropTables.json"
        this.obj := json.load(FileRead(A_ScriptDir "\Debug_DropTables.json"))

        ;;; retrieve drop images
        this._GetItemImages()

        ;;; modify drop tables
        this._ObjMergeDupeTables()
        this._ObjMergeDupeDrops()
        this._ObjMergeSmallTables()
        this._ObjRenameTables()
        
        SplashTextOff
    }

    /*
        param <input>       = {integer} number of drop
        returns             = {object} found drop information
    */
    GetDrop(input) {
        loop % this.obj.length() {
            table := A_Index
            loop % this.obj[table].tableDrops.length() {
                totalItems++
                If (totalItems = input) {
                    output := this.obj[table].tableDrops[A_Index]
                    break, 2
                }
            }
        }
        return output
    }

    ; purpose = download images of all items in the drop table
    _GetItemImages() {
        loop % this.obj.length() {
            obj := this.obj[A_Index].tableDrops
            loop % obj.length() {
                html := obj[A_Index].itemImage
                itemHtml := SubStr(html, InStr(html, "/w/") + 3) ; normal name 'Slayer's enchantment' html wiki name 'Slayer%27s_enchantment'
                itemHtml := SubStr(itemHtml, 1, InStr(itemHtml, ">") - 2)
                item := obj[A_Index].itemName

                path := g_itemImgsPath "\" item ".png"
                If FileExist(path)
                    continue

                If (item = "Nothing") ; 'Nothing' is a drop in rare drop tables
                    FileCopy, % A_ScriptDir "\res\img\Nothing.png", % path, 0
                else {
                    url := wiki.GetImageUrl(itemHtml)
                    DownloadToFile(url, path)
                }

                tooltip % A_Index
            }
        }
    }

    ; purpose = merge the drops from smaller tables into a main table
    _ObjMergeSmallTables() {
        mergedDrops := {}

        loop % this.obj.length() {
            table := A_Index
            drops := this.obj[A_Index].tableDrops

            If (drops.length() > this.minTableSize)
                Continue

            loop % drops.length() {
                mergedDrops.push(drops[A_Index])
            }

            this.obj.Delete(table)
        }

        ; restructure entire drop tables object because .Delete() changes the object layout to indexed eg.   "2": {    "tableDrops": [
        newObj := {}
        loop % this.obj.length() {
            If !(this.obj[A_Index].tableTitle)
                continue
            newObj.push(this.obj[A_Index])
        }
        this.obj := newObj

        output := {}
        output.tableDrops := mergedDrops
        output.tableTitle := "Main"
        this.obj.push(output)
    }

    ; purpose = merge the drops from duplicate tables eg. in 'black demon'
    _ObjMergeDupeTables() {
        output := {}
        totalTables := this.obj.length()

        loop % totalTables {
            title := this.obj[A_Index].tableTitle
            drops := this.obj[A_Index].tableDrops
            
            foundDuplicateTable := this._FindTable(output, title)

            If (foundDuplicateTable) {
                loop % drops.length()
                    output[foundDuplicateTable].tableDrops.push(drops[A_Index])
            }
            else {
                entry := {}
                entry.tableTitle := title
                entry.tableDrops := drops
                output.push(entry)
            }
        }
        this.obj := output
    }

    ; purpose = merge duplicate drops inside each table which can occur eg. in 'black demon'
    _ObjMergeDupeDrops() {
        obj := this.obj.clone()

        loop % obj.length() {
            table := obj[A_Index].tableDrops
            newTable := {}

            ; rebuild this table drop by drop, checking if the drop is not already in the new table
            loop % table.length() {
                drop := table[A_Index]
                
                isDuplicate := this._FindDrop(newTable, drop)

                If !(isDuplicate)
                    newTable.push(drop)
            }

            obj[A_Index].tableDrops := newTable
        }
        this.obj := obj
    }

    ; purpose = rename categories eg. 'weapons and armor' into 'gear'
    _ObjRenameTables() {
        obj := this.obj

        For table in obj {
            
            renamedTitle := ""

            Switch obj[table].tableTitle {
                case "Weapons and armour":
                    renamedTitle := "Gear"
                case "Rare Drop Table":
                    renamedTitle := "RDT"
                case "Rare and Gem drop table":
                    renamedTitle := "RDT + Gems"
                case "Fletching materials":
                    renamedTitle := "Fletch"
            }

            If (renamedTitle)
                obj[table].tableTitle := renamedTitle
        }
    }

    /*
        param <obj>         = {object} drop tables object
        param <input>       = {string} 'tableTitle' to be searched
        returns             = {integer} table index if found, false if not
    */
    _FindTable(obj, input) {
        If !(obj.length())
            return false

        loop % obj.length() {
            title := obj[A_Index].tableTitle

            If (title = input)
                return A_Index
        }
        return false
    }

    /*
        param <obj>         = {object} drop table object
        param <input>       = {object} item drop object
        returns             = {bool} true if found inside specified drop table
    */
    _FindDrop(obj, input) {
        If !(obj.length())
            return false
        
        loop % obj.length() {
            haystack := obj[A_Index]

            If (haystack.itemName = input.itemName) and (haystack.itemQuantity = input.itemQuantity)
                return true
        }
        return false
    }
}