/*
 Purpose: Retrieve item id's and prices

 Links:
    prices      = https://prices.runescape.wiki/api/v1/osrs/latest
    item names  = https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/items-summary.json
    item names  = https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/items-complete.json

    Note: intially use item id's to search
        If search by item name is required various options are available, for example:
            - saving osrsbox-db-master\docs\items-json to assets and downloading a missing item id from the osrsbox api whenever encountered
                note: over updates item id's apparently CAN change so that would make this a bit more complicated
            - using the weekly downloaded monsters-complete to create a list with the item names and id's <- added benefit this could only include items in drop tables
*/

Class ClassDatabaseItems {
    wikiApiPricesUrl := "https://prices.runescape.wiki/api/v1/osrs/latest"

    __New() {
        ; check if the file is already available
        obj := json.load(FileRead(PATH_DATABASE_ITEMS))
        
        ; check file creation time
        If FileExist(PATH_DATABASE_ITEMS) {
            FileGetTime, OutputVar , % PATH_DATABASE_ITEMS, C
            hoursOld := A_Now
            EnvSub, hoursOld, OutputVar, Hours
        }

        ; update the file if neccessary
        If !IsObject(obj) or (hoursOld > 24)
            obj := this._Update()

        ; check if we now have a valid input
        If !IsObject(obj)
            Msg("Error", A_ThisFunc, "Unable to continue without wiki api price info")

        this.obj := obj
    }

    GetPrice(id) {
        price := this.obj[id]

        high := price.high
        low := price.low

        average := (high - low) / 2 + low
        average := Round(average)

        return average
    }

    ; create new item database file using the prices from the wiki & item names from osrsbox
    _Update() {
        msgbox updating

        ; download file
        obj := json.load(DownloadToString(this.wikiApiPricesUrl))
        ; obj := json.load(FileRead(A_ScriptDir "\Dev\items-database-wikiPrices.json"))
        obj := obj.data
        
        ; check if valid
        If !IsObject(obj) {
            Msg("Info", A_ThisFunc, "Not able to receive valid input from the wiki api:`n`n" this.wikiApiPricesUrl)
            return false
        }

        ; save to disk for future use
        FileDelete, % PATH_DATABASE_ITEMS
        FileAppend, % json.Dump(obj,,2), % PATH_DATABASE_ITEMS
        return obj
    }
}