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
    If (!IsObject(DB_SETTINGS)) {
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
    defaultSettings.selectedLogFile := ""
    defaultSettings.selectedMob := "Vorkath"
    defaultSettings.selectedMobs := {"Vorkath": "", "Ice giant": ""}

    for defaultSetting in defaultSettings {
        If (!DB_SETTINGS.HasKey(defaultSetting))
            DB_SETTINGS[defaultSetting] := defaultSettings[defaultSetting]
    }

    If (DB_SETTINGS.logGuiDropSize < MIN_DROP_SIZE) or (DB_SETTINGS.logGuiDropSize > MAX_DROP_SIZE)
        DB_SETTINGS.logGuiDropSize := 33 ; 33 is close to ingame inventory
    
    If (DB_SETTINGS.logGuiMaxRowDrops < MIN_ROW_LENGTH) or (DB_SETTINGS.logGuiMaxRowDrops > MAX_ROW_LENGTH)
        DB_SETTINGS.logGuiMaxRowDrops := 8

    If (DB_SETTINGS.logGuiTablesMergeBelowX < MIN_TABLE_SIZE)
        DB_SETTINGS.logGuiTablesMergeBelowX := 27 ; 27 = rdt
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

    If !(OutputAssociatedVar) {
        tooltip
        return
    }

    If !(DROP_LOG.TripActive()) {
        tooltip No trip started!
        SetTimer, disableTooltip, -250
        return
    }
     If (DROP_LOG.DeathActive()) {
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

    If InStr(obj.quantity, "#") or InStr(obj.quantity, "-")
        obj.quantity := QUANTITY_GUI.Get(obj)
    If !(obj.quantity)
        return

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

DownloadMissingItemImages() {
    allMonstersApiUrl := "https://www.osrsbox.com/osrsbox-db/monsters-complete.json"
    allItemsApiUrl := "https://www.osrsbox.com/osrsbox-db/items-complete.json"
    file := A_ScriptDir "\res\items-complete.json"

    ; retrieve json
    SplashTextOn, 350, 100, % A_ScriptName " - " A_ThisFunc "()", Loading database
    If (!FileExist(file)) {
        content := DownloadToString(allMonstersApiUrl)
        content := json.load(content)
        FileAppend, % json.dump(content,,2), % file
    }
    obj := json.load(FileRead(file))

    ; loop images
    downloadList := {}
    loop % obj.length() {
        mob := obj[A_Index]
        drops := mob.drops
        loop % drops.length() {
            drop := drops[A_Index]

            downloadList[drop.name] := ""
        }
    }
    SplashTextOff

    SplashTextOn, 350, 100, % A_ScriptName A_Space "-" A_ThisFunc "()", Retrieving images
    totalItems := downloadList.count()
    for item in downloadList
    {
        ControlSetText, Static1, % A_Index " / " totalItems " - " item, % A_ScriptName A_Space "-" A_ThisFunc "()"
        DownloadItemImages(item)
    }
    SplashTextOff
}

DownloadItemImages(item) {
    id := RUNELITE_API.GetItemId(item)
    wikiImageUrl := WIKI_API.GetImages(item, 50)

    ; wiki small
    path := DIR_ITEM_ICONS "\" id ".png"
    If (!IsPicture(path))
        FileDelete % path
    If (!FileExist(path)) {
        url := wikiImageUrl.icon
        DownloadImageOrQuit(url, path)
        imgAddBorder(path, 5)
    }
    
    ; wiki detail
    path := DIR_ITEM_DETAIL "\" id ".png"
    If (!IsPicture(path))
        FileDelete % path
    If (!FileExist(path)) {
        url := wikiImageUrl.detail
        DownloadImageOrQuit(url, path)
        imgResize(path, 50)
        imgAddBorder(path, 10)
    }

    ; runelite
    path := DIR_ITEM_RUNELITE "\" id ".png"
    If (!IsPicture(path))
        FileDelete % path
    If (!FileExist(path)) {
        url := RUNELITE_API.GetItemImgUrl(item)
        DownloadImageOrQuit(url, path)
    }
}

DownloadImageOrQuit(url, path) {
    DownloadToFile(url, path)

    IsPicture := IsPicture(path, picW, picH)

    If (!IsPicture) or (picW < 5) or (picH < 5) {
        msgbox, 4160, ,
        ( LTrim
            %A_ThisFunc%: ERROR!!!!

            URL
            '%url%'

            PATH
            '%path%'

            WIDTH
            '%picW%'

            HEIGHT
            '%picH%'

            Closing..
        )
        exitapp
        return
    }
}