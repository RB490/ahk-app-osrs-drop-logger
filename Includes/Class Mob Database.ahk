
/*
 Purpose: Retrieve mob info from osrsbox

 Links:
    https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-complete.json
    https://github.com/osrsbox/osrsbox-db/blob/master/docs/monsters-complete.json



          "id":1,
      "name":"Molanisk",
      "last_updated":"2021-04-26",
    "category":[
         "molanisk"
      ],
    "wiki_name":"Molanisk",
    "wiki_url":"https://oldschool.runescape.wiki/w/Molanisk",
    "drops" {

    }


*/

Class ClassMobDatabase {
    url := "https://raw.githubusercontent.com/osrsbox/osrsbox-db/master/docs/monsters-complete.json"

    __New() {
        P.Get(A_ThisFunc, "Loading mob database")
        
        input := FileRead(PATH_DATABASE_MOBS)
        obj := json.load(input)

        ; update the database if we need to
        If FileExist(PATH_DATABASE_MOBS) {
            FileGetTime, OutputVar , % PATH_DATABASE_MOBS, C
            hoursOld := A_Now
            EnvSub, hoursOld, OutputVar, Hours
        }

        If !IsObject(obj) or (hoursOld > 168) { ; if mob list unavailable or more than x hours old
            this.Update()
        }

        P.Destroy()
    }

    Update() {
        P.Get(A_ThisFunc, "Updating mob database", A_Space, A_Space) ; title-text1-bar1-bar1text

        If DEBUG_MODE
            input := FileRead(A_ScriptDir "\Dev\monsters-complete-1page.txt")
        else
            input := DownloadToString(this.url)

        inputObj := json.load(input), P.B1(inputObj.Count())

        ; cleanup the obj by only keeping usefull data
        outputObj := []
        for mob_id in inputObj {
            outputObj[mob_id] := [] ; add this mob to our new output object
            outputObj[mob_id].id := inputObj[mob_id].id
            outputObj[mob_id].name := inputObj[mob_id].name
            outputObj[mob_id].wiki_name := inputObj[mob_id].wiki_name
            outputObj[mob_id].wiki_url := inputObj[mob_id].wiki_url
            outputObj[mob_id].last_updated := inputObj[mob_id].last_updated
            outputObj[mob_id].category := inputObj[mob_id].category
            outputObj[mob_id].drops := inputObj[mob_id].drops
            
            P.B1()
            P.T2(inputObj[mob_id].wiki_name A_Space "(ID: " inputObj[mob_id].id ")")

            ; msgbox % json.dump(outputObj,,2)
            ; sleep 1000
        }
        P.Destroy()

        ; save to disk
        FileDelete, % PATH_DATABASE_MOBS
        FileAppend, % json.dump(outputObj,,2), % PATH_DATABASE_MOBS
    }

}