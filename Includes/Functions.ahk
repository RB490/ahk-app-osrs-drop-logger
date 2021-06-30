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

    ; set default setting values for empty keys & make sure some settings are within spec
    obj := ValidateSettings(obj)

    return obj
}

ValidateSettings(settingsObj) {
    obj := settingsObj

    ; default setting values
    defaultSettings := {}
    defaultSettings.guiStatsX := ""
    defaultSettings.guiStatsY := ""
    defaultSettings.guiStatsW := 570
    defaultSettings.guiStatsH := 400
    defaultSettings.guiLog_X := ""
    defaultSettings.guiLog_Y := ""
    defaultSettings.guiLog_AutoShowStats := false
    defaultSettings.guiLog_DropSize := 33
    defaultSettings.guiLog_MaxRowDrops := 8
    defaultSettings.guiLog_TablesMergeBelowX := 27
    defaultSettings.guiLog_ItemImageType := "Wiki Detailed"
    defaultSettings.previousLogFile := ""
    defaultSettings.previousMob := "Vorkath"
    defaultSettings.setupHasRan := false

    ; verify all keys exist
    for defaultSetting in defaultSettings {
        If !obj.HasKey(defaultSetting)
            obj[defaultSetting] := defaultSettings[defaultSetting]
    }


    ; gui log
    If (obj.guiLog_DropSize < GUI_LOG_MIN_DROP_SIZE) or (obj.guiLog_DropSize > GUI_LOG_MAX_DROP_SIZE)
        obj.guiLog_DropSize := 33 ; 33 is close to ingame inventory
    
    If (obj.guiLog_MaxRowDrops < GUI_LOG_MIN_ROW_LENGTH) or (obj.guiLog_MaxRowDrops > GUI_LOG_MAX_ROW_LENGTH)
        obj.guiLog_MaxRowDrops := 8

    If (obj.guiLog_TablesMergeBelowX < GUI_LOG_MIN_TABLE_SIZE)
        obj.guiLog_TablesMergeBelowX := 27 ; 27 = rdt

    ; gui stats
    If (guiStatsW < 140)
        obj.guiStatsW := 570
    If (guiStatsH < 140)
        obj.guiStatsH := 400

    return obj
}

GetGuiLogImageType() {
    switch SCRIPT_SETTINGS.guiLog_ItemImageType
    {
        case "Wiki Small": output := DIR_ITEM_IMAGES_ICONS
        case "Wiki Detailed": output := DIR_ITEM_IMAGES_DETAILED
    }
    return output
}




















































; -------------------- Images --------------------

DownloadMobImage(mobName, mobId) {
    path := DIR_MOB_IMAGES "\" mobId ".png"
    If IsValidImage(path)
        return
    If FileExist(path)
        FileDelete % path
    url := WIKI_API.img.GetMobImage(mobName)

    DownloadImageOrReload(url, path)
    ResizeImage(path, 100)
}

DownloadDropImage(itemName, itemId) {
    If !IsValidImage(DIR_ITEM_IMAGES_ICONS "\" itemId ".png") or !IsValidImage(DIR_ITEM_IMAGES_DETAILED "\" itemId ".png")
        wikiImageUrlObj := WIKI_API.img.GetItemImages(itemName, 50)

    ; wiki small
    path := DIR_ITEM_IMAGES_ICONS "\" itemId ".png"
    If !IsValidImage(path) {
        FileDelete % path
        url := wikiImageUrlObj.icon
        DownloadImageOrReload(url, path)
        AddBorderToImage(path, 5)
    }
    
    ; wiki detail
    path := DIR_ITEM_IMAGES_DETAILED "\" itemId ".png"
    If !IsValidImage(path) {
        FileDelete % path
        url := wikiImageUrlObj.detail
        DownloadImageOrReload(url, path)
        ResizeImage(path, 50)
        AddBorderToImage(path, 10)
    }
}

DownloadImageOrReload(url, path) {
    DownloadToFile(url, path)

    If !IsValidImage(path) {
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

; input (img) = {string} path to image
AddBorderToImage(img, borderSize := 10) {
    If !pToken := Gdip_Startup()
        Msg("Error", A_ThisFunc, "Gdiplus failed to start")
    pBitmapFile1 := Gdip_CreateBitmapFromFile(img)
    imgW := Gdip_GetImageWidth(pBitmapFile1), imgH := Gdip_GetImageHeight(pBitmapFile1)
    ; w:=width+60
    ; h:=height+60

    If (imgW > imgH)
        canvasSize := imgW
    else
        canvasSize := imgH

    canvasSize += borderSize

    ; canvasW := imgW + borderSize
    ; canvasH := imgH + borderSize

    imgX := (canvasSize - imgW) / 2
    imgY := (canvasSize - imgH) / 2

    pBitmap := Gdip_CreateBitmap(canvasSize, canvasSize)
    G := Gdip_GraphicsFromImage(pBitmap)

    ; pBrush := Gdip_BrushCreateSolid(0xffffffff)
    ; Gdip_FillRectangle(G, pBrush, 0, 0, canvasW, canvasH)
    ; Gdip_DeleteBrush(pBrush)

    Gdip_DrawImage(G, pBitmapFile1, imgX, imgY, imgW, imgH, 0, 0, imgW, imgH)
    Gdip_DisposeImage(pBitmapFile1)

    Gdip_SaveBitmapToFile(pBitmap, img)
    Gdip_DisposeImage(pBitmap)
    Gdip_DeleteGraphics(G)
    Gdip_Shutdown(pToken)
}

ResizeImage(img, scale) {
    If !pToken := Gdip_Startup() ; Start Gdip
        Msg("Error", A_ThisFunc, "Gdiplus failed to start")

    SplitPath, img, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive

    if FileExist(img)
        ResConImg(img, scale, scale, OutNameNoExt,,, true)
    else
        Msg("Error", A_ThisFunc, "File Error, File not found.")
    Gdip_Shutdown(pToken)  ; Close Gdip
}

IsValidImage(img, pix := 3) { ; adamant dart is 9x17
    IsValidImage := IsPicture(img, imgW, imgH)
    If !IsValidImage or (imgW < pix) or (imgH < pix)
        return false
    return true
}

; -------------------- Images --------------------