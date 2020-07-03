; get drop table for mob and modify it to be usable. also retrieve drop images
Class ClassDropTable {
    
    /*
        param <input>       = {integer} number of drop going through all tables
        returns             = {object} found drop information
    */
    GetDrop(input) {
        tables := this.obj
        loop % tables.length() {
            table := tables[A_Index]
            drops := table.drops

            loop % drops.length() {
                drop := drops[A_Index]
                loopedDrops++
                If (loopedDrops = input)
                    return ObjFullyClone(drop)
            }
        }
        msgbox, 4160, , % A_ThisFunc ": Could not find drop '" input "'!"
    }

    ; input = {string} wiki page containing drop tables
    Get(input) {
        If !(DEBUG_MODE)
            SplashTextOn, 300, 75, % A_ScriptName, Retrieving drop table for %input%...

        this.obj := WIKI_API.GetDroptables(input)
        If !(this.obj.length()) {
            msgbox, 4160, , % A_ThisFunc ": Could not find drop table for '" input "'!"
            SplashTextOff
            return false
        }

        this._TablesMergeDuplicates()
        this._TablesMergeBelowX()
        this._TablesRenaming()
        this._DropsDeleteDuplicates()
        this._DropsMergeQuantities()
        ; this._DropsGetImages()

        SplashTextOff
        return true
    }

    ; purpose = merge the drops from tables with identical names eg. '100%' in 'black demon'
    _TablesMergeDuplicates() {
        output := {}
        tables := this.obj
        loop % tables.length() {
            table := tables[A_Index]
            drops := table.drops

            found := this._FindTable(output, table.title)
            If (found) ; add drops from duplicate table to the one already in output
                loop % drops.length() 
                    output[found].drops.push(drops[A_Index])
            else
                output.push(table)
        }
        this.obj := output
    }

    ; purpose = merge tables below x into a main table
    _TablesMergeBelowX() {
        output := {}
        
        tables := this.obj
        loop % tables.length() {
            table := tables[A_Index]
            drops := table.drops

            If (drops.length() >= DB_SETTINGS.logGuiTablesMergeBelowX) {
                output.push(table)
                Continue
            }

            loop % drops.length() {
                If !(this._FindTable(output, "main"))
                    output.push({title: "Main", drops: {}})
                
                output[1].drops.push(drops[A_Index])
            }
        }
        this.obj := output
    }

    ; purpose = give tables a shorter name
    _TablesRenaming() {
        tables := this.obj

        For table in tables {
            newTitle := ""

            Switch tables[table].title {
                case "Weapons and armour":
                    newTitle := "Gear"
                case "Rare Drop Table":
                    newTitle := "RDT"
                case "Rare and Gem drop table":
                    newTitle := "RDT + Gems"
                case "Fletching materials":
                    newTitle := "Fletch"
            }

            If (newTitle)
                tables[table].title := newTitle
        }
    }

    ; purpose = remove drops with identical names and quantitites
    _DropsDeleteDuplicates() {
        tables := this.obj
        loop % tables.length() {
            table := tables[A_Index]
            output := {}
            loop % table.drops.length() {
                drop := table.drops[A_Index]
                isDuplicate := this._FindDrop(output, drop, "matchQuantity")
                If (isDuplicate)
                    Continue
                output.push(drop)
            }
            this.obj[A_Index].drops := output
        }
    }

    ; purpose = merge identical drops combining their quantitites
    _DropsMergeQuantities() {
        tables := this.obj
        loop % tables.length() {
            table := tables[A_Index]
            output := {}
            loop % table.drops.length() {
                drop := table.drops[A_Index]

                isDuplicate := this._FindDrop(output, drop)
                If (isDuplicate) {
                    output[isDuplicate].quantity .= "#" drop.quantity
                    Continue
                }
                output.push(drop)
            }
            this.obj[A_Index].drops := output
        }
    }

    ; retrieve any missing images
    _DropsGetImages() {
        tables := this.obj
        loop % tables.length() {
            table := tables[A_Index]
            loop % table.drops.length() {
                drop := table.drops[A_Index]
                If (drop.name = "Nothing")
                    Continue
                DownloadItemImages(drop.name)
            }
        }
    }
    
    /*
        param <tables>      = {object} drop tables object
        param <tableTitle>  = {string} table title to be searched
        returns             = {integer} table index if found, false if not
    */
    _FindTable(tables, tableTitle) {
        loop % tables.length() {
            table := tables[A_Index]
            If (table.title = tableTitle)
                return A_Index
        }
        return false
    }

    /*
        param <table>       = {object} a single drop table
        param <drop>        = {object} drop to be searched
        returns             = {integer} index of found item or false
    */
    _FindDrop(table, drop, matchQuantity := false) {
        loop % table.length() {
            haystack := table[A_Index]
            
            If (matchQuantity) {
                If (haystack.name = drop.name) and (haystack.quantity = drop.quantity)
                    return A_Index
                else
                    Continue
            }
            else
                If (haystack.name = drop.name)
                    return A_Index
            
        }
        return false
    }
}