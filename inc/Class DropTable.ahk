class class_DropTable {
    
    /*
        param <input>       = {string} context sensitive wiki page containing drop tables eg. 'Vorkath'
        purpose             = retrieve a mob's drop table, download drops and mob image
        returns             = nothing
    */
    GetDrops(input) {
        If !(g_debug)
            SplashTextOn, 300, 75, % A_ScriptName, Retrieving drop table for %input%...
        
        this.obj := wiki.GetDroptables(input)
        this._GetImages()

        SplashTextOff
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

    /*
        param <input>       = nothing
        purpose             =   rename categories eg. 'weapons and armor' into 'gear'
                                merge categories with less than X items into a main category
        returns             = {object} formatted object for the log gui
    */
    GetDropsFormatted() {
        obj := this.obj.Clone()

        ; rename categories eg. 'weapons and armor' into 'gear'
        For table in obj {
            Switch obj[table].tableTitle {
                case "Weapons and armour":
                    obj[table].tableTitle := "Gear"
                case "Rare Drop Table":
                    obj[table].tableTitle := "RDT"
                case "Fletching materials":
                    obj[table].tableTitle := "Fletch"
            }
        }

        ; msgbox end of %A_ThisFunc%
        return this.obj
    }
}