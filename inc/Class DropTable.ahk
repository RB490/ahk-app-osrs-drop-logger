class class_DropTable {
    
    /*
        param <input>       = {string} context sensitive wiki page containing drop tables eg. 'Vorkath'
        purpose             = retrieve a mob's drop table, download drops and mob image
        returns             = nothing
    */
    GetDrops(input) {
        this.minTableSize := 5 ; tables below this many itmes get merged together
        
        If !(g_debug)
            SplashTextOn, 300, 75, % A_ScriptName, Retrieving drop table for %input%...
        
        ; this.obj := wiki.GetDroptables(input)
        ; this._GetImages()
        ; FileAppend, % json.dump(this.obj,,2), % A_ScriptDir "\Debug_DropTables.json"
        this.obj := json.load(FileRead(A_ScriptDir "\Debug_DropTables.json"))
        this.obj := this._MergeDuplicateTables()
        this.obj := this._MergeDuplicateTableDrops()
        obj := this._MergeSmallTables()
        this.obj.push(obj)
        this.obj := this._RenameTables()

        SplashTextOff
    }

    /*
        param <input>       = {integer} number of drop
        purpose             = return found drop in drop table
        returns             = {object} drop information
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

    /*
        param <input>       = nothing
        purpose             = download images of all items in the drop table
        returns             = nothing
    */
    _GetImages() {
        loop % this.obj.length() {
            obj := this.obj[A_Index].tableDrops
            loop % obj.length() {
                html := obj[A_Index].itemImage
                item := obj[A_Index].itemName
                
                ; retrieve image relative path eg. '/images/a/a5/Superior_dragon_bones.png?105c4"'
                html := SubStr(html, InStr(html, "src=") + 6)
                html := SubStr(html, 1, InStr(html, "?") - 1)
                
                link := wiki.url "/" html
                path := g_itemImgsPath "\" item ".png"
                
                If !FileExist(path)
                    DownloadToFile(link, path)
            }
        }
    }

    _MergeSmallTables() {
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
        return output
    }

    /*
        param <input>       = nothing
        purpose             =   rename categories eg. 'weapons and armor' into 'gear'
                                merge categories with less than X items into a main category
        returns             = {object} formatted object for the log gui
    */
    _RenameTables() {
        obj := this.obj.Clone()

        ; rename categories eg. 'weapons and armor' into 'gear'
        For table in obj {
            Switch obj[table].tableTitle {
                case "Weapons and armour":
                    obj[table].tableTitle := "Gear"
                case "Rare Drop Table":
                    obj[table].tableTitle := "RDT"
                case "Rare and Gem drop table":
                    obj[table].tableTitle := "RDT + Gems"
                case "Fletching materials":
                    obj[table].tableTitle := "Fletch"
            }
        }
        return obj
    }

    ; returns             = {object} a rebuild drop tables object merging the drops from duplicate tables eg. in 'black demon'
    _MergeDuplicateTables() {
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
        return output
    }

    /*
        param <obj>         = drop tables object
        param <input>       = 'tableTitle' to be searched
        returns             = {integer} 0 if not found else table index
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

    _MergeDuplicateTableDrops() {
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
        return obj
    }

    ; obj = drop table object, input = item drop object
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