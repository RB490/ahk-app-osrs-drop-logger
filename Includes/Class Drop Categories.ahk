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
        ; try to load file from disk
        obj := json.load(FileRead(PATH_DATABASE_CATEGORIES))
        fileAge := A_Now
        fileAge -= obj.lastUpdated, Hours

        ; update the file if neccessary
        If !(obj.lastUpdated) or (fileAge > 4368) { ; 4368 hours = 182 days
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
    Get(dropTable, maxMainTableSize) {
        output := []
        output["Main"] := {}


        ; sort entire drop table into categories
        for i, drop in dropTable {
            name := drop.name
            category := this._GetCategoryForDrop(drop.name)
            If !category
                category := "Main"

            ; create this category if necessary
            If !IsObject(output[category])
                output[category] := []

            output[category].push(drop)
        }

        ; start merging categories into the 'main' category, starting with the smallest one until merging the smallest one would go over the max size
        ; loop the amount of categories that exist
        loop, % output.Count() {
            ; check if we reached the main drop table max size
            If (output["Main"].length() >= maxMainTableSize)
                break
            
            ; merge the smallest category into the main drop table, if it doesnt exceed the limit
            smallestCategory := this._GetSmallestCategory(output)
            If (output["Main"].length() + smallestCategory.size >= maxMainTableSize)
                break

            ; merge this table
            for i, drop in output[smallestCategory.name]
                output["Main"].push(drop)
            output.Delete(smallestCategory.name)
            
            ; msgbox % json.dump(output["Main"],,2)
        }
        return output
    }

    /*
        Purpose
            Used by Get()

        input
            DropTable sorted in categories
        
        output
            object.name
            object.size
    */
    _GetSmallestCategory(dropTableWithCategories) {
        input := dropTableWithCategories
        categoryList := {}
        output := {}

        for category in input {
            If (category = "Main")
                Continue
            categoryList[input[category].length()] := category
        }
        
        output.name := categoryList[categoryList.MinIndex()]
        output.size := categoryList.MinIndex()

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
            matchCategory := "Main"

        ; finish up
        return matchCategory
    }

    _Update() {
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


        /*
            loop through categories
            loop through sub categories adding the items to the main categories
        */
        output := {lastUpdated: A_Now, content: {}}
        for category in categories {
            obj["content"][category] := []
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
                    output["content"][category].push(drop)
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