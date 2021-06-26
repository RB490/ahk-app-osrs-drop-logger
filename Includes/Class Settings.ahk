Class ClassSettings {
    __New() {
        this.Load()
    }

    Load() {
        ; read settings from disk
        input := FileRead(PATH_SCRIPT_SETTINGS)
        obj := json.load(input)

        ; if not available, write default settings
        If !IsObject(obj) {
            obj := []
            obj.previousMob := ""
        }

        this.obj := obj
    }

    Save() {
        FileDelete, % PATH_SCRIPT_SETTINGS
        FileAppend, % json.Dump(this.obj,,2), % PATH_SCRIPT_SETTINGS
    }
}