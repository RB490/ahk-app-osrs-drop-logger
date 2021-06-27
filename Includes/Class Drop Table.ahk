Class ClassDropTable {
    Get(mobName) {
        ; inform about the waiting time
        ; If !DEBUG_MODE
            P.Get(A_ThisFunc, "Retrieving drop table for " mobName)
        
        ; get drop table
        obj := MOB_DB.GetDropTable(mobName)
        If !IsObject(obj)
            return false

        ; download drop images
        for count, drop in obj
            DownloadDropImage(drop.name, drop.id)
        
        ; finish up
        P.Destroy()
        return obj
    }

    
}