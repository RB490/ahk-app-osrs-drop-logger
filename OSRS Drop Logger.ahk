; Script options
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    CoordMode, Mouse, Screen
    SetBatchLines, -1
    OnExit("ExitFunc")
    OnMessage(0x201, "OnWM_LBUTTONDOWN")
    #MaxMem, 400 ; downloadMissingItemImages()

; Global vars
    global  PROJECT_WEBSITE             := "https://github.com/RB490/ahk-app-osrs-drop-logger"
    global  DEBUG_MODE                  := true
    global  DIR_ITEM_ICON               := A_ScriptDir "\res\img\item\icon"
    global  DIR_ITEM_DETAIL             := A_ScriptDir "\res\img\item\detail"
    global  DIR_ITEM_RUNELITE           := A_ScriptDir "\res\img\item\runelite"
    global  DIR_MOB_IMAGES              := A_ScriptDir "\res\img\mobs"
    global  DIR_GUI_ICONS               := A_ScriptDir "\res\img\ico"
    global  PATH_RUNELITE_JSON          := A_ScriptDir "\res\runelite.json"
    global  PATH_SETTINGS               := A_ScriptDir "\settings.json"
    global  DB_SETTINGS                 := {}
    global  SELECTED_DROPS              := {}
    global  RUNELITE_API                := new ClassApiRunelite
    global  WIKI_API                    := new ClassApiWiki
    global  DROP_LOG                    := new ClassDropLog
    global  DROP_STATS                  := new ClassDropStats
    global  DROP_TABLE                  := new ClassDropTable
    global  LOG_GUI                     := new ClassGuiLog("Log Gui")
    global  MAIN_GUI                    := new ClassGuiMain("Main Gui")
    global  QUANTITY_GUI                := new ClassGuiQuantity("Quantity Gui")
    global  SETTINGS_GUI                := new ClassGuiSettings("Settings Gui")
    global  STATS_GUI                   := new ClassGuiStats("Stats Gui")
    global  _BTN_CLEAR_DROPS            ; log gui
    global  _BTN_TOGGLE_TRIP            ; log gui
    global  _BTN_TOGGLE_DEATH           ; log gui
    global  _BTN_NEW_TRIP               ; log gui
    global  _BTN_UNDO                   ; log gui
    global  _BTN_REDO                   ; log gui
    global  _BTN_LOG_MENU               ; log gui
    global  _BTN_KILL                   ; log gui
    global  _MAIN_GUI_BTN_LOG           ; main gui
    global  MIN_DROP_SIZE               := 10
    global  MAX_DROP_SIZE               := 80
    global  MIN_ROW_LENGTH              := 1
    global  MAX_ROW_LENGTH              := 25
    global  MIN_TABLE_SIZE              := 1
    global  ITEM_IMAGE_TYPES            := "Wiki Small|Wiki Detailed|RuneLite"

; Auto-execute
    FileCreateDir, % DIR_ITEM_ICON
    FileCreateDir, % DIR_ITEM_DETAIL
    FileCreateDir, % DIR_ITEM_RUNELITE
    FileCreateDir, % DIR_MOB_IMAGES
    LoadSettings()
    If (DEBUG_MODE)
        Goto debugAutoexec 
    MAIN_GUI.Setup()
return

; Global hotkeys
    ~^s::
        If !(A_IsCompiled)
            reload
    return
    ~f1::
        If !(DEBUG_MODE)
            return
    return

; Labels
    disableTooltip:
        tooltip
    return
    menuHandler:
    return
    updateStats:
        DROP_STATS.UpdateBasicStats()
        DROP_STATS.UpdateAdvancedStats()
    return
    debugAutoexec:
        ; SETTINGS_GUI.Setup()
        DB_SETTINGS.selectedMob := "Ice giant"
        DROP_TABLE.Get(DB_SETTINGS.selectedMob)
        DB_SETTINGS.selectedLogFile := "D:\Downloads\debugLog.json"
        DROP_LOG.Load(DB_SETTINGS.selectedLogFile)
        LOG_GUI.Setup()
    return

; Includes
    #Include, <JSON>
    #Include, <class gui>
    #Include, <CommandFunctions>
    #Include, <Gdip_all>
    #Include, %A_ScriptDir%\inc
    #Include Class Api RuneLite.ahk
    #Include Class Api Wiki.ahk
    #Include Class Drop Log.ahk
    #Include Class Drop Stats.ahk
    #Include Class Drop Table.ahk
    #Include Class Gui Log.ahk
    #Include Class Gui Main.ahk
    #Include Class Gui Quantity.ahk
    #Include Class Gui Settings.ahk
    #Include Class Gui Stats.ahk
    #Include Func Gui About.ahk
    #Include Functions.ahk