; Script options
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    SetBatchLines, -1
    OnExit("ExitFunc")
    OnMessage(0x201, "OnWM_LBUTTONDOWN")

; Global vars
    global  DEBUG_MODE                  := true
    global  PATH_ITEM_IMAGES            := A_ScriptDir "\res\img\items"
    global  PATH_MOB_IMAGES             := A_ScriptDir "\res\img\mobs"
    global  PATH_ITEM_IDS               := A_ScriptDir "\res\itemIds.json"
    global  PATH_SETTINGS               := A_ScriptDir "\settings.json"
    global  PATH_DROP_LOG               := "D:\Downloads\debugLog.json"
    global  SETTINGS_OBJ                := {}
    global  SELECTED_DROPS              := {}
    global  RUNELITE_API                := new ClassApiRunelite
    global  WIKI_API                    := new ClassApiWiki
    global  DROP_LOG                    := new ClassDropLog
    global  DROP_TABLE                  := new ClassDropTable
    global  LOG_GUI                     := new ClassGuiLog("Log Gui")
    global  MOB_GUI                     := new ClassGuiMob("Mob Gui")
    global  QUANTITY_GUI                := new ClassGuiQuantity("Quantity Gui")
    global  _BTN_CLEAR_DROPS            ; log gui
    global  _BTN_TOGGLE_TRIP            ; log gui
    global  _BTN_TOGGLE_DEATH           ; log gui
    global  _BTN_NEW_TRIP               ; log gui
    global  _BTN_UNDO                   ; log gui
    global  _BTN_REDO                   ; log gui
    global  _BTN_KILL                   ; log gui

; Auto-execute
    FileCreateDir, % PATH_ITEM_IMAGES
    FileCreateDir, % PATH_MOB_IMAGES
    SETTINGS_OBJ := json.load(FileRead(PATH_SETTINGS))
        If !(IsObject(SETTINGS_OBJ))
            SETTINGS_OBJ := {}

    DROP_TABLE.Get("fire giant")

    FileDelete, % PATH_DROP_LOG
    DROP_LOG.Load(PATH_DROP_LOG)
    LOG_GUI.Setup()
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