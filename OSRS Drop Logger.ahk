; Script options
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    SetBatchLines, -1
    OnExit("ExitFunc")
    OnMessage(0x201, "OnWM_LBUTTONDOWN")

; Global vars
    global  g_debug             := true
    global  g_path_itemImages   := A_ScriptDir "\res\img\items"
    global  g_path_mobImages    := A_ScriptDir "\res\img\mobs"
    global  g_path_itemIds      := A_ScriptDir "\res\itemIds.json"
    global  g_path_settings     := A_ScriptDir "\settings.json"
    global  g_path_dropLog      := "D:\Downloads\debugLog.json"
    global  g_selectedMob
    global  g_selectedDrops     := {}
    global  runeLiteApi         := new class_api_runeLite
    global  wikiApi             := new class_api_wiki
    global  dropLog             := new class_drop_log
    global  dropTable           := new class_drop_table
    global  logGui              := new class_gui_logger("Log Gui")
    global  mobGui              := new class_gui_mob("Mob Gui")
    global  quantityGui         := new class_gui_quantity("Quantity Gui")
    global  settings            := {}

; Auto-execute
    FileCreateDir, % g_path_itemImages
    FileCreateDir, % g_path_mobImages
    settings := json.load(FileRead(g_path_settings))
        If !(IsObject(settings))
            settings := {}

    dropTable.Get("black demon")
    ; dropLog.Load("some input")
    ; dropLog.StartTrip()
    ; logGui.Setup()
    ; mobGui.Setup()
    
    ; msgbox hi there

    dropLog.Load(g_path_dropLog)
    logGui.Setup()
return

; Global hotkeys
    ~^s::reload
    f1::
    return

; Labels
    disableTooltip:
        tooltip
    return
    menuHandler:
    return

; Includes
    #Include, <JSON>
    #Include, <class gui>
    #Include, <CommandFunctions>
    #Include, %A_ScriptDir%\inc
    #Include Class Api RuneLite.ahk
    #Include Class Api Wiki.ahk
    #Include Class Drop Log.ahk
    #Include Class Drop Table.ahk
    #Include Class Gui Log.ahk
    #Include Class Gui Mob.ahk
    #Include Class Gui Quantity.ahk
    #Include Functions.ahk