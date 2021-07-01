/*
    Purpose =   
        Create and maintain a list of item drop categories

    Sources =
        https://oldschool.runescape.wiki/api.php?action=query&list=categorymembers&cmlimit=500&format=json&cmtitle=Category:Runes
        https://www.mediawiki.org/wiki/API:Categorymembers
        https://oldschool.runescape.wiki/api.php?action=help&modules=query
        https://www.osrsbox.com/blog/2018/12/12/scraping-the-osrs-wiki-part1/#extract-all-categories
*/

Class ClassDropCategories {
    baseUrl := "https://oldschool.runescape.wiki/api.php?action=query&list=categorymembers&cmlimit=500&format=json&cmtitle=Category:"       

    __New() {
        obj := json.load(FileRead(PATH_DATABASE_CATEGORIES))
        
        ; check when last updated
        If FileExist(PATH_DATABASE_ITEMS) {
            FileGetTime, OutputVar , % PATH_DATABASE_ITEMS, C
            daysOld := A_Now
            EnvSub, daysOld, OutputVar, Days
        }

        ; determine if we need to update
        If !IsObject(obj) or (daysOld > 182)
            obj := this._Update()

        ; check if category list is available
        If !IsObject(obj)
            Msg("Error", A_ThisFunc, "Unable to continue without the required files")

        this.obj := obj
    }

    /*
        Input = object array with drops
            Exammple:
                {
                "id": 1623,
                "name": "Uncut emerald",
                },
                {
                "id": 1623,
                "name": "Uncut sapphire",
                },

        Output = object array containing category arrays with the drops in them
            Example:
            Gems {
                {
                "id": 1623,
                "name": "Uncut emerald",
                },
            },
            Misc {
                {
                "id": 1623,
                "name": "Uncut sapphire",
                },
            }
    */
    Get(dropTable) {
        output := []

        for index, drop in dropTable {
            name := drop.name
            
            category := this._GetCategoryForDrop(drop.name)

            If !IsObject(output[category])
                output[category] := []

            output[category].push(drop)
        }
        return output
    }

    _GetCategoryForDrop(inputDrop) {
        ; go through every category
        for category in this.obj {
            
            
            ; go through every drop in this category
            for index, drop in this.obj[category] {


                ; found category for inputdrop
                If (drop = inputDrop) {
                    
                    ; matchCategory
                    matchCategory := category

                    ; stop searching
                    break, 2

                }
            }
        }

        ; couldnt find category for this item, so:
        If !matchCategory
            matchCategory := "Misc"

        ; finish up
        return matchCategory
    }

    _Update() {
        /*
            Items
                Runes
                Gems
            Misc
                Herbs

            loop through categories
                loop through sub categories adding the items to the main categories
        */

        categories := []
        categories.Farming := ["Herbs", "Seeds"]
        categories.Food := ["Fish", "Potions"]
        categories.Gems := ["Gems"]
        categories.Skilling := ["Logs", "Ores"]
        categories.Runes := ["Runes"]
        
        categories.Ammunition := ["Ammunition_slot_items"]
        
        categories.Armour := []
        categories.Armour.Push("Body_slot_items")
        categories.Armour.Push("Cape_slot_items")
        categories.Armour.Push("Feet_slot_items")
        categories.Armour.Push("Hands_slot_items")
        categories.Armour.Push("Head_slot_items")
        categories.Armour.Push("Legs_slot_items")
        categories.Armour.Push("Neck_slot_items")
        categories.Armour.Push("Ring_slot_items")
        categories.Armour.Push("Shield_slot_items")

        categories.Weapons := ["Two-handed_slot_items", "Weapon_slot_items"]

        output := []

        for category in categories {
            output[category] := []
            for index, subCategory in categories[category] {
                ; get drops list for this category
                dropsList := this._GetDropListFor(subCategory)
                
                ; if failed to fetch a category
                If (dropsList = false) {
                    Msg("Info", A_ThisFunc, "Was unable to fetch drops list for category: " subCategory "`n`nUnable to rebuild drop category list")
                    return
                }

                ; add this subcategory to the main category
                for index, drop in dropsList
                    output[category].push(drop)
            }
        }

        ; save output to desk
        FileDelete, % PATH_DATABASE_CATEGORIES
        FileAppend, % json.dump(output,,2), % PATH_DATABASE_CATEGORIES

        return output
    }

    /*
        Purpose =
            Fetch list of drops in a wiki category
        
        Input (category) =
            Valid wiki category preferably in 'url format' so underscores instead of spaces and only the first letter capitalized: "Runes" or "Crafting_items"

        Example api output = 
            {
                "batchcomplete": "",
                "query": {
                    "categorymembers": [
                    {
                        "ns": 0,
                        "pageid": 3252,
                        "title": "Fire rune"
                    },
                    {
                        "ns": 0,
                        "pageid": 10091,
                        "title": "Air rune"
                    }
                }
            }

    */
    _GetDropListFor(category) {
        ; get wiki api result
        obj := json.load(DownloadToString(this.baseUrl category))

        ; check if result is valid
        If !IsObject(obj) {
            return false
        }
        
        ; select the result we need from the api
        obj := obj.query.categorymembers

        ; collect the drops
        output := []
        for index, drop in obj {
            drop := drop.title

            ; ignore certain results
            If InStr(drop, "Category")
                Continue

            ; save to output
            output.push(drop)
        }

        return output
    }
}