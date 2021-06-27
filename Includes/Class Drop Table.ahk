Class ClassDropTable {
    Get(mobName) {
        obj := MOB_DB.GetDropTable(mobName)
        If !IsObject(obj)
            return false
        return obj
    }
}