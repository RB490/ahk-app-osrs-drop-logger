
/*
 Purpose: Retrieve mob list from osrsbox

 Links:
    https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/data/monsters/monsters-wiki-page-titles.json
    https://github.com/osrsbox/osrsbox-db/blob/master/data/monsters/monsters-wiki-page-titles.json

*/

Class ClassMobList {
    url := "https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/data/monsters/monsters-wiki-page-titles.json"

    __New() {
        this.Load()
    }

    Load() {
        ; check if a mob list is available
        input := FileRead(PATH_DATABASE_MOBLIST)
        obj := json.load(input)
        
        ; retrieve a new mob list if necessary
        If FileExist(PATH_DATABASE_MOBLIST) {
            FileGetTime, OutputVar , % PATH_DATABASE_MOBLIST, C
            hoursOld := A_Now
            EnvSub, hoursOld, OutputVar, Hours
        }

        If !IsObject(obj) or (hoursOld > 84) { ; if mob list unavailable or more than x hours old
            obj := this.Retrieve()
            If !IsObject(obj)
                Msg("Error", A_ThisFunc, "A mob list is not locally available and it was not possible to retrieve a new one")
        }
        this.obj := obj

        ; sucessfully loaded the mob list
        return true
    }

    Retrieve() {
        ; retrieve mob list
        input := DownloadToString(this.url)

        ; verify information
        output := json.load(input)
        If !IsObject(output) {
            Msg("Info", A_ThisFunc, "Could not retrieve new mob list from`n`n" this.url)
            return false
        }

        ; store retrieved mob list on disk
        FileDelete, % PATH_DATABASE_MOBLIST
        FileAppend, % JSON.dump(output,,2), % PATH_DATABASE_MOBLIST

        ; return retrieved mob list
        return output
    }

    Get() {
        return this.obj
        ; return json.dump(this.obj,,2)
    }
}