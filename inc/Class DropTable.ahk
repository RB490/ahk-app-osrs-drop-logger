; purpose = modify and retrieve drop tables information
class class_DropTable {
    __New() {
        this.minTableSize := 32 ; tables below this many itemes get merged together. rdt has 33 drops
    }

    /*
        param <input>       = {string} context sensitive wiki page containing drop tables eg. 'Vorkath'
        purpose             = retrieve a mob's drop table and download drop item images
        returns             = {boolean} true if successfull
    */
    GetDrops(input) {
        If !(g_debug)
            SplashTextOn, 300, 75, % A_ScriptName, Retrieving drop table for %input%...

        ;;; retrieve drop tables
        this.obj := wiki.GetDroptables(input)
        If !(IsObject(this.obj))
            return false
        ; FileAppend, % json.dump(this.obj,,2), % A_ScriptDir "\info\example class_wiki.GetDroptables('Black_demon').json"
        ; this.obj := json.load(FileRead(A_ScriptDir "\info\example class_wiki.GetDroptables('Black_demon').json"))

        ;;; retrieve drop images
        this._GetItemImages()

        ;;; modify drop tables
        this._ObjMergeDupeTables()
        this._ObjMergeDupeDrops()
        this._ObjMergeSmallTables()
        this._ObjRenameTables()
        
        SplashTextOff
        return true
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
                item := obj[A_Index].itemName
                If (item = "Nothing")
                    continue
                itemId := runeLite.GetId(item)

                path := g_path_itemImages "\" itemId ".png"
                If FileExist(path)
                    continue

                url := runeLite.GetImgUrl(itemId)

                DownloadToFile(url, path)
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