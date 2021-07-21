Class ClassDropTable {
    Get(mobName) {
        If !DEBUG_MODE
            P.Get(A_ThisFunc, "Retrieving drop table for " mobName)
        
        ; get drop table
        obj := OSRS.GetMobTable(mobName)
        If !IsObject(obj) {
            Msg("Info", A_ThisFunc, "Could not retrieve drop table for" A_Space mobName)
            return false
        }

        ; download drop images
        for count, drop in obj
            GetDropImage(drop.name, drop.id)
        
        ; combine duplicate drops
        obj := this._CombineIdenticalDropsWithDifferentQuantities(obj)

        ; sort drop table into categories. todo: separate RDT, Gem drop table, talisman drop table. etc.
        obj := DROP_CATEGORIES.Get(obj, SCRIPT_SETTINGS.guiLog_MaxTableSize)
    
        ; msgbox % json.dump(obj,,2)
        ; OutputDebug, % json.dump(obj,,2)

        ; finish up
        P.Destroy()
        return obj
    }

    _FindItemQuantitiesInTableAndRemoveThem(ByRef inputTable, inputItem) {
        ; get object we can work on without messing up the table
        obj := ObjFullyClone(inputTable)
        outputTable := {}
        outputQuantities := {inputItem.quantity: inputItem.quantity}

        ; collect inputItem quantities
        loop % obj.length() {
            drop := obj.pop()
            If (drop.name = inputItem.name) {
                outputQuantities[drop.quantity] := drop.quantity
            }
            else
                outputTable.push(drop)
        }
        
        ; add inputItem to outputTable
        for quantity in outputQuantities
            quantities .= quantity "#"
        quantities := RTrim(quantities, "#")
        inputItem.quantity := quantities
        ; outputTable.push(inputItem)
        
        ; If InStr(quantities, "#") {
        ;     msgbox % json.dump(inputItem,,2)
        ;     OutputDebug, % json.dump(outputTable,,2)
        ;     msgbox % json.dump(outputTable,,2)

        ; }

        ; msgbox % outputTable[inputItem].quantity

        ; OutputDebug, % json.dump(outputTable,,2)
        ; msgbox % json.dump(outputTable,,2)


        ; overwrite inputTable
        ; If (inputItem.name = "Coins") {
        ;     clipboard := "inputTable Before:`n`n" json.dump(inputTable,,2)
        ;     msgbox % "inputTable Before:`n`n" json.dump(inputTable,,2)
        ; }
        inputTable := outputTable
        ; If (inputItem.name = "Coins") {

        ;     clipboard := "inputTable After:`n`n" json.dump(inputTable,,2)
        ;     msgbox % "inputTable After:`n`n" json.dump(inputTable,,2)
        ; }
        ; msgbox % inputItem.name

        return quantities
    }

    ; eg: coins 50, coins 60 into one drop with quantity 50#60 ClassGuiQuantity uses # as separators between quantities
    _CombineIdenticalDropsWithDifferentQuantities(table) {
        /*
            remove (pop) one drop from the drop table
            find identical named drops from the drop table, also remove those, and save their quantities
            after processing all drops add this drop to the output
        */
        
        output := {}
        loop, % table.length() {
            ; take a drop
            thisItem := table.pop()
            If !IsObject(thisItem) ; we are removing entries from the table so might do more loops then required
                Break

            ; get quantities for this drop
            quantities := this._FindItemQuantitiesInTableAndRemoveThem(table, thisItem)
            thisItem.quantity := quantities


            output.push(thisItem)

            ; If (thisItem.name = "Coins") {
                
                ; clipboard := json.dump(table,,2)
                ; msgbox % json.dump(table,,2)
                ; msgbox % thisItem.name " quantity:`n`n " json.dump(quantities)
            ; }

            ; clipboard := json.dump(output,,2)
            ; msgbox % json.dump(output,,2)

            ; msgbox % json.dump(thisItem,,2)
        }

        ; clipboard := json.dump(output,,2)
        ; msgbox % json.dump(output,,2)

        return output
        loop, % table.length() {
            ; take one drop
            sourceDrop := table.pop()

            ; find all duplicate occurences of this drop
            for i, drop in table {
                ; found duplicate drop
                If (drop.name = sourceDrop.name) {
                    ; save its quantity
                    sourceDrop.quantity := sourceDrop.quantity "#" drop.quantity
                }

                ; remove duplicate drop
                table.Delete(i-1)
            }

            ; add drop to output
            obj := {}
            obj.name := sourceDrop.name
            obj.id := sourceDrop.id
            obj.quantity := sourceDrop.quantity
            output.push(obj)
            
            ; msgbox % json.dump(output,,2)
        }

        return output
    }
}