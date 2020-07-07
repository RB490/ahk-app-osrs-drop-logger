ExitFunc(ExitReason, ExitCode) {
    SaveSettings()
    DROP_LOG.Save()
}

SaveSettings() {
    STATS_GUI.SavePos()
    LOG_GUI.SavePos()

    FileDelete, % PATH_SETTINGS
    FileAppend, % json.dump(DB_SETTINGS,,2), % PATH_SETTINGS
}

LoadSettings() {
    DB_SETTINGS := json.load(FileRead(PATH_SETTINGS))
    If !IsObject(DB_SETTINGS) {
        msgbox, 4160, , % A_ThisFunc ": Resetting settings"
        DB_SETTINGS := {}
    }
    ValidateSettings()
}

ValidateSettings() {
    defaultSettings := {}
    defaultSettings.guiLogX := ""
    defaultSettings.guiLogY := ""
    defaultSettings.guiStatsX := ""
    defaultSettings.guiStatsY := ""
    defaultSettings.guiStatsW := ""
    defaultSettings.guiStatsH := ""
    defaultSettings.logGuiAutoShowStats := false
    defaultSettings.logGuiDropSize := 33
    defaultSettings.logGuiMaxRowDrops := 8
    defaultSettings.logGuiTablesMergeBelowX := 27
    defaultSettings.logGuiItemImageType := "Wiki Detailed"
    defaultSettings.selectedLogFile := ""
    defaultSettings.selectedMob := "Vorkath"
    defaultSettings.selectedMobs := {"Vorkath": "", "Ice giant": ""}

    for defaultSetting in defaultSettings {
        If !DB_SETTINGS.HasKey(defaultSetting)
            DB_SETTINGS[defaultSetting] := defaultSettings[defaultSetting]
    }

    If (DB_SETTINGS.logGuiDropSize < MIN_DROP_SIZE) or (DB_SETTINGS.logGuiDropSize > MAX_DROP_SIZE)
        DB_SETTINGS.logGuiDropSize := 33 ; 33 is close to ingame inventory
    
    If (DB_SETTINGS.logGuiMaxRowDrops < MIN_ROW_LENGTH) or (DB_SETTINGS.logGuiMaxRowDrops > MAX_ROW_LENGTH)
        DB_SETTINGS.logGuiMaxRowDrops := 8

    If (DB_SETTINGS.logGuiTablesMergeBelowX < MIN_TABLE_SIZE)
        DB_SETTINGS.logGuiTablesMergeBelowX := 27 ; 27 = rdt
}

GetItemImageDirFromSetting() {
    switch DB_SETTINGS.logGuiItemImageType
    {
        case "Wiki Small": output := DIR_ITEM_ICON
        case "Wiki Detailed": output := DIR_ITEM_DETAIL
        case "RuneLite": output := DIR_ITEM_RUNELITE
    }
    return output
}

IsInteger(input) {
    If input is integer
        return true
}

; input = {string} 'encode' or 'decode'
; purpose = DROP_LOG.GetFormattedLog() uses timestamps to put events in the right order,
;   add A_MSec to prevent multiple actions in the same second overwriting eachother
; note = turns out decoding isn't necessary as 'EnvAdd' / 'EnvSub' ignore the added msecs
ConvertTimeStamp(encodeOrDecode, timeStamp) {
    sleep 1 ; wait 1 milisecond so actions in DROP_LOG.GetFormattedLog() don't execute on the same milisecond
    
    If (encodeOrDecode = "encode") {
        output := timeStamp A_MSec
    }

    If (encodeOrDecode = "decode")
        output := SubStr(timeStamp, 1, StrLen(timeStamp) - 3)

    return output
}

OnWM_LBUTTONDOWN(wParam, lParam, msg, hWnd) {
    MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl
    GuiControlGet, OutputAssociatedVar, Name, % OutputVarControl

    If !OutputAssociatedVar {
        tooltip
        return
    }
    If !DROP_LOG.TripActive() {
        tooltip No trip started!
        SetTimer, disableTooltip, -250
        return
    }
     If DROP_LOG.DeathActive() {
        tooltip You're dead!
        SetTimer, disableTooltip, -250
        return
    }

    id := SubStr(OutputAssociatedVar, InStr(OutputAssociatedVar, "#") + 1)
    obj := DROP_TABLE.GetDrop(id)
    Obj.Delete("iconWikiUrl")
    Obj.Delete("highAlchPrice")
    Obj.Delete("price")
    Obj.Delete("rarity")

    If !IsInteger(obj.quantity) { ; contains separator '#' or '-'
        LOG_GUI.Disable()
        QUANTITY_GUI.Load(obj)
        return
    }
    SELECTED_DROPS.push(obj)

    LOG_GUI.Update()
}

; input (img) = {string} path to image
ImgAddBorder(img, borderSize := 10) {
    If !pToken := Gdip_Startup()
    {
        msgbox, 16, , % A_ThisFunc ": Gdiplus failed to start`n`nClosing.."
        ExitApp
    }
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

ImgResize(img, scale) {
    If !pToken := Gdip_Startup() {  ; Start Gdip
        msgbox, 16, , % A_ThisFunc ": Gdiplus failed to start`n`nClosing.."
        ExitApp
    }

    SplitPath, img, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive

    if FileExist(img)
        ResConImg(img, scale, scale, OutNameNoExt,,, true)
        ; ResConImg(img, scale, scale, OutFileName, "bmp",, true, 32)
        ; ResConImg(OriginalFile, NewWidth:="", NewHeight:="", NewName:="", NewExt:="", NewDir:="", PreserveAspectRatio:=true, BitDepth:=24)
    else
        msgbox, 16, , % A_ThisFunc ": File Error, File not found."
    Gdip_Shutdown(pToken)  ; Close Gdip
}

LoadOSRSBoxApi() {
    If IsObject(DB_OSRSBOX.obj)
        return
    allMonstersApiUrl := "https://www.osrsbox.com/osrsbox-db/monsters-complete.json"
    allItemsApiUrl := "https://www.osrsbox.com/osrsbox-db/items-complete.json"
    file := PATH_OSRSBOX_JSON

    ; retrieve json
    SplashTextOn, 350, 100, % A_ScriptName " - " A_ThisFunc "()", Loading database
    If !FileExist(file) {
        content := DownloadToString(allMonstersApiUrl)
        content := json.load(content)
        FileAppend, % json.dump(content,,2), % file
    }
    DB_OSRSBOX.obj := obj := json.load(FileRead(file))

    ; get info
    mobList := {}
    dropList := {}
    loop % obj.length() {
        mob := obj[A_Index]
        If mob.name and !InStr(mob.wiki_name, "(") ; 'Archer (Ardougne)' gets turned into 'Archer'
            mobList[mob.name] := ""
        drops := mob.drops
        loop % drops.length() {
            drop := drops[A_Index]

            dropList[drop.name] := ""
        }
    }
    DB_OSRSBOX.mobList := mobList
    DB_OSRSBOX.dropList := dropList
    SplashTextOff
}

DownloadAllMobDroptables() {
    LoadOSRSBoxApi()

    SplashTextOn, 350, 100, % A_ScriptName A_Space "-" A_ThisFunc "()", Retrieving drop tables
    totalMobs := DB_OSRSBOX.mobList.count()
    for mob in DB_OSRSBOX.mobList
    {
        ControlSetText, Static1, % A_Index " / " totalMobs " - " mob, % A_ScriptName A_Space "-" A_ThisFunc "()"
        WIKI_API.table.GetDroptable(mob)
    }
    SplashTextOff
}

DownloadMissingMobImages() {
    LoadOSRSBoxApi()

    SplashTextOn, 350, 100, % A_ScriptName A_Space "-" A_ThisFunc "()", Retrieving drop tables
    totalMobs := DB_OSRSBOX.mobList.count()
    for mob in DB_OSRSBOX.mobList
    {
        ControlSetText, Static1, % A_Index " / " totalMobs " - " mob, % A_ScriptName A_Space "-" A_ThisFunc "()"
        DownloadMobImage(mob)
    }
    SplashTextOff
}

DownloadMobImage(mob) {
    path := DIR_MOB_IMAGES "\" mob ".png"
    If IsPicWithDimension(path)
        return
    If FileExist(path)
        FileDelete % path
    url := WIKI_API.img.GetMobImage(mob)

    DownloadImageElseReload(url, path)
    imgResize(path, 100)
}

DownloadMissingItemImages() {
    LoadOSRSBoxApi()

    SplashTextOn, 350, 100, % A_ScriptName A_Space "-" A_ThisFunc "()", Retrieving images
    totalItems := DB_OSRSBOX.dropList.count()
    for item in DB_OSRSBOX.dropList
    {
        ControlSetText, Static1, % A_Index " / " totalItems " - " item, % A_ScriptName A_Space "-" A_ThisFunc "()"
        DownloadItemImages(item)
    }
    SplashTextOff
}

DownloadItemImages(item) {
    id := RUNELITE_API.GetItemId(item)
    If !IsPicWithDimension(DIR_ITEM_ICON "\" id ".png") or !IsPicWithDimension(DIR_ITEM_DETAIL "\" id ".png")
        wikiImageUrl := WIKI_API.img.GetItemImages(item, 50)

    ; wiki small
    path := DIR_ITEM_ICON "\" id ".png"
    If !IsPicWithDimension(path) {
        FileDelete % path
        url := wikiImageUrl.icon
        DownloadImageElseReload(url, path)
        imgAddBorder(path, 5)
    }
    
    ; wiki detail
    path := DIR_ITEM_DETAIL "\" id ".png"
    If !IsPicWithDimension(path) {
        FileDelete % path
        url := wikiImageUrl.detail
        DownloadImageElseReload(url, path)
        imgResize(path, 50)
        imgAddBorder(path, 10)
    }

    ; runelite
    path := DIR_ITEM_RUNELITE "\" id ".png"
    If !IsPicWithDimension(path) {
        FileDelete % path
        url := RUNELITE_API.GetItemImgUrl(item)
        DownloadImageElseReload(url, path)
    }
}

IsPicWithDimension(pic, pix := 3) { ; adamant dart is 9x17
    IsPic := IsPicture(pic, picW, picH)
    If !IsPic or (picW < pix) or (picH < pix)
        return false
    return true
}

DownloadImageElseReload(url, path) {
    DownloadToFile(url, path)

    If !IsPicWithDimension(path) {
        msgbox, 4160, ,
        ( LTrim
            %A_ThisFunc%: Could not retrieve image

            URL
            '%url%'

            PATH
            '%path%'

            WIDTH
            '%picW%'

            HEIGHT
            '%picH%'

            Reloading..
        )
        reload
        return
    }
}