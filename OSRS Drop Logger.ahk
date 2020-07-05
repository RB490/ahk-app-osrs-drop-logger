; Script options
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    CoordMode, Mouse, Screen
    SetBatchLines, -1
    OnExit("ExitFunc")
    OnMessage(0x201, "OnWM_LBUTTONDOWN")
    #MaxMem, 400 ; downloadMissingItemImages()

; Global vars
    Global PROJECT_WEBSITE   := "https://github.com/RB490/ahk-app-osrs-drop-logger"
    , DEBUG_MODE             := true
    , DIR_ITEM_ICON          := A_ScriptDir "\res\img\item\icon"
    , DIR_ITEM_DETAIL        := A_ScriptDir "\res\img\item\detail"
    , DIR_ITEM_RUNELITE      := A_ScriptDir "\res\img\item\runelite"
    , DIR_MOB_IMAGES         := A_ScriptDir "\res\img\mobs"
    , DIR_GUI_ICONS          := A_ScriptDir "\res\img\ico"
    , PATH_RUNELITE_JSON     := A_ScriptDir "\res\runelite.json"
    , PATH_SETTINGS          := A_ScriptDir "\settings.json"
    , DB_SETTINGS            := {}
    , SELECTED_DROPS         := {}
    , RUNELITE_API           := new ClassApiRunelite
    , WIKI_API               := new ClassApiWiki
    , DROP_LOG               := new ClassDropLog
    , DROP_STATS             := new ClassDropStats
    , DROP_TABLE             := new ClassDropTable
    , LOG_GUI                := new ClassGuiLog("Log Gui")
    , MAIN_GUI               := new ClassGuiMain("Main Gui")
    , QUANTITY_GUI           := new ClassGuiQuantity("Quantity Gui")
    , SETTINGS_GUI           := new ClassGuiSettings("Settings Gui")
    , STATS_GUI              := new ClassGuiStats("Stats Gui")
    , MIN_DROP_SIZE          := 10
    , MAX_DROP_SIZE          := 80
    , MIN_ROW_LENGTH         := 1
    , MAX_ROW_LENGTH         := 25
    , MIN_TABLE_SIZE         := 1
    , ITEM_IMAGE_TYPES       := "Wiki Small|Wiki Detailed|RuneLite"

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
        ; debug := new QUANTITY_GUI.Debug(QUANTITY_GUI)
        ; debug.Load()

        ; return
        ; SETTINGS_GUI.Setup()
        ; DB_SETTINGS.selectedMob := "Ice giant"
        DROP_TABLE.Get(DB_SETTINGS.selectedMob)
        DB_SETTINGS.selectedLogFile := "D:\Programming and projects\ahk-app-osrs-drop-logger\info\ClassDropLog.json"
        DROP_LOG.Load(DB_SETTINGS.selectedLogFile)
        LOG_GUI.Setup()
        ; STATS_GUI.Setup()
        ; DROP_STATS.UpdateBasicStats()
        ; DROP_STATS.UpdateAdvancedStats()
    return

; Includes
    #Include, <JSON>
    #Include, <class gui>
    #Include, <CommandFunctions>
    #Include, <Gdip_all>
    #Include, <LoadPictureType>
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