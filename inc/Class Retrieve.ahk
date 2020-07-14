Class ClassRetrieve {
    MobImages() {
        totalMobs := OSRSBOX_API.mobs.count()
        P.Get(A_ThisFunc, "Retrieving mob images", totalMobs, A_Space)
        for mob in OSRSBOX_API.mobs {
            P.B1(), P.T2(A_Index " / " totalMobs " - " mob)
            DownloadMobImage(mob)
        }
        P.Destroy()
    }

    DropImages() {
        totalDrops := OSRSBOX_API.Drops.count()
        P.Get(A_ThisFunc, "Retrieving drop images", totalDrops, A_Space)
        for Drop in OSRSBOX_API.Drops {
            P.B1(), P.T2(A_Index " / " totalDrops " - " Drop)
            DownloadDropImages(Drop)
        }
        P.Destroy()
    }

    DropTables() {
        totalMobs := OSRSBOX_API.mobs.count()
        P.Get(A_ThisFunc, "Retrieving mob drop tables", totalMobs, A_Space)
        for mob in OSRSBOX_API.mobs {
            P.B1(), P.T2(A_Index " / " totalMobs " - " mob)
            WIKI_API.table.GetDroptable(mob)
        }
        P.Destroy()
    }
}