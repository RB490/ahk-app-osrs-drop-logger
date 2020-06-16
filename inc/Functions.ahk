ExitFunc(ExitReason, ExitCode) {
    FileDelete, % A_ScriptDir "\settings.json"
    FileAppend, % json.dump(settings,,2), % A_ScriptDir "\settings.json"
}

UpdateItemImages() {
    obj := json.load(FileRead("D:\Programming and projects\ahk-osrs-drop-logger\tempItemIds.txt"))
    
    PATH_GE_ICON := g_itemImgsPath "\ge\icon"
    PATH_GE_ICON_LARGE := g_itemImgsPath "\ge\icon_large"
    PATH_WIKI_ICON := g_itemImgsPath "\wiki\icon"
    PATH_WIKI_ICON_LARGE := g_itemImgsPath "\wiki\icon_large"

    FileCreateDir, % PATH_GE_ICON
    FileCreateDir, % PATH_GE_ICON_LARGE
    FileCreateDir, % PATH_WIKI_ICON
    FileCreateDir, % PATH_WIKI_ICON_LARGE

    for a, item in obj {
        item := item.name

        URL_GE_ICON := GetGrandExchangeImgUrl(item, "small")
        URL_GE_ICON_LARGE := GetGrandExchangeImgUrl(item, "large")
        URL_WIKI_ICON := wiki.GetImageUrl(item)
        URL_WIKI_ICON_LARGE := wiki.GetImageUrl(item)
        
        If (urlGeIconLarge)
            msgbox valid
        else
            msgbox invalid

        DownloadToFile(urlGeIconLarge, g_itemImgsPath "\icon_large\" item ".png")
        DownloadToFile(urlGeIcon, g_itemImgsPath "\icon\" item ".png")

        msgbox
    }

    ; loop % obj.length() {
    ;     obj
    ; }
}

GetGrandExchangeImgUrl(input, size := "large") {
    id := runeLite.GetId(input)
    apiUrl := "http://services.runescape.com/m=itemdb_oldschool/api/catalogue/detail.json?item=" id
    response := DownloadToString(apiUrl)
    If InStr(response, "<!DOCTYPE") ; contains html aka error page
        return false
    obj := json.load(response)
    If (size = "large")
        itemUrl := obj.item.icon_large
    else
        itemUrl := obj.item.icon
    return itemUrl
}

OnWM_LBUTTONDOWN(wParam, lParam, msg, hWnd) {
    MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl
    GuiControlGet, OutputAssociatedVar, Name, % OutputVarControl

    If !(OutputAssociatedVar) {
        tooltip
        return
    }

    If !(dropLog.TripActive()) {
        tooltip No trip started!
        SetTimer, disableTooltip, -250
        return
    }

    id := SubStr(OutputAssociatedVar, InStr(OutputAssociatedVar, "#") + 1)
    obj := dropTable.GetDrop(id)
    Obj.Delete("itemHighAlch")
    Obj.Delete("itemImage")
    Obj.Delete("itemPrice")
    Obj.Delete("itemRarity")

    g_selectedDrops.push(obj)

    loop % g_selectedDrops.length()
        drops .= g_selectedDrops[A_Index].itemQuantity " x " g_selectedDrops[A_Index].itemName ", "
    drops := RTrim(drops, ", ")

    logGui.SetText("edit1", drops)
}

ObjFullyClone(obj)
{
	nobj := obj.Clone()
	for k,v in nobj
		if IsObject(v)
			nobj[k] := A_ThisFunc.(v)
	return nobj
}