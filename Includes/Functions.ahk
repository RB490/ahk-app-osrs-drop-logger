ExitFunc() {
    SaveSettings()
}

SaveSettings() {
    FileDelete, % PATH_SCRIPT_SETTINGS
    FileAppend, % json.Dump(SCRIPT_SETTINGS,,2), % PATH_SCRIPT_SETTINGS
}

LoadSettings() {
    ; read settings from disk
    input := FileRead(PATH_SCRIPT_SETTINGS)
    obj := json.load(input)

    ; if not available, write default settings
    If !IsObject(obj) {
        obj := []
    }

    return obj
}

; -------------------- Images --------------------

DownloadMobImage(mobName) {
    path := DIR_MOB_IMAGES "\" mobName ".png"
    If IsImg(path)
        return
    If FileExist(path)
        FileDelete % path
    url := WIKI_API.img.GetMobImage(mobName)

    DownloadImageOrReload(url, path)
    ImgResize(path, 100)
}

DownloadImageOrReload(url, path) {
    DownloadToFile(url, path)

    If !IsImg(path) {
        msgbox, 4160, ,
        ( LTrim
            %A_ThisFunc%: Could not retrieve image

            URL
            '%url%'

            PATH
            '%path%'

            Reloading..
        )
        reload
        return
    }
}

ImgResize(img, scale) {
    If !pToken := Gdip_Startup() ; Start Gdip
        Msg("Error", A_ThisFunc, "Gdiplus failed to start")

    SplitPath, img, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive

    if FileExist(img)
        ResConImg(img, scale, scale, OutNameNoExt,,, true)
    else
        Msg("Error", A_ThisFunc, "File Error, File not found.")
    Gdip_Shutdown(pToken)  ; Close Gdip
}

IsImg(pic, pix := 3) { ; adamant dart is 9x17
    IsPic := IsPicture(pic, picW, picH)
    If !IsPic or (picW < pix) or (picH < pix)
        return false
    return true
}