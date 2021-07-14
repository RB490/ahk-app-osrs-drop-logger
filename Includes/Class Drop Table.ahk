Class ClassDropTable {
    Get(mobName) {
        If !DEBUG_MODE
            P.Get(A_ThisFunc, "Retrieving drop table for " mobName)
        
        ; get drop table
        obj := DB_MOB.GetDropTable(mobName)
        If !IsObject(obj) {
            Msg("Info", A_ThisFunc, "Could not retrieve drop table for" A_Space mobName)
            return false
        }

        ; download drop images
        for count, drop in obj
            GetDropImage(drop.name, drop.id)
        
        ; sort drop table into categories. todo: separate RDT, Gem drop table, talisman drop table. etc.
        obj := DROP_CATEGORIES.Get(obj)

        ; finish up
        P.Destroy()
        return obj
    }

    
}