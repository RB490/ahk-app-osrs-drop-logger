/*
 Purpose: Retrieve item prices

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

Class ClassItemPrices {
    wikiApiPricesUrl := "https://prices.runescape.wiki/api/v1/osrs/latest"

    __New() {
        ; try to load file from disk
        obj := json.load(FileRead(PATH_DATABASE_PRICES))
        fileAge := A_Now
        fileAge -= obj.lastUpdated, Hours

        ; update the file if neccessary
        If !(obj.lastUpdated) or (fileAge > 720) { ; 720 hours = 30 days
            output := this._Update()
            If output.lastUpdated
                obj := output
            else
                Msg("Info", A_ThisFunc, "Update failed")
        }

        ; verify input
        If !obj.lastUpdated
            Msg("Error", A_ThisFunc, "Data unavailable")

        this.obj := obj.content
    }

    Get(id) {
        price := this.obj[id]

        high := price.high
        low := price.low

        average := (high - low) / 2 + low
        average := Round(average)

        return average
    }

    ; create new item database file using the prices from the wiki & item names from osrsbox
    _Update() {
        P.Get(A_ThisFunc, "Updating wiki prices") ; title-text1-bar1-bar1text

        ; download file
        obj := json.load(DownloadToString(this.wikiApiPricesUrl))
        ; obj := json.load(FileRead(A_ScriptDir "\Dev\items-database-wikiPrices.json"))
        obj := obj.data
        
        ; check if valid
        If !IsObject(obj) {
            Msg("Info", A_ThisFunc, "Not able to receive valid input from the wiki api:`n`n" this.wikiApiPricesUrl)
            return false
        }

        ; only store items that are inside drop tables
        output := {lastUpdated: A_Now, content: {}}
        dropList := OSRS.GetItems()
        for id in obj
            If dropList.HasKey(id)
                output["content"][id] := obj[id]

        ; save to disk for future use
        FileDelete, % PATH_DATABASE_PRICES
        FileAppend, % json.Dump(output,,2), % PATH_DATABASE_PRICES

        P.Destroy()
        return output
    }
}