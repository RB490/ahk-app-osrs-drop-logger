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
        
        ; remove unnecesary information from the drops, such as 'members' and 'noted' so str2hex doesnt get too big in guilog adding associated vars
        obj := this._CleanupDrops(obj)

        ; combine duplicate drops
        obj := this._CombineIdenticalDropsWithDifferentQuantities(obj)

        ; sort drop table into categories. todo: separate RDT, Gem drop table, talisman drop table. etc.
        obj := DROP_CATEGORIES.Get(obj, SCRIPT_SETTINGS.guiLog_MaxTableSize)

        ; finish up
        P.Destroy()
        return obj
    }

    _CleanupDrops(inputTable) {
        for i, drop in inputTable {
            drop.Delete("rolls")
            drop.Delete("members")
            drop.Delete("noted")
        }
        return inputTable
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
        ; outputTable.push(inputItem) ; adding the item in the 'main' method

        ; overwrite inputTable
        inputTable := outputTable
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
        }
        return output
    }
}