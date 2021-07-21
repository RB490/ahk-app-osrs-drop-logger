; Script options
    Menu, Tray, MainWindow ; open debug window for compiled script
    SetBatchLines, -1
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    CoordMode, Mouse, Screen
    SetBatchLines, -1
    OnExit("ExitFunc")
    OnMessage(0x201, "ON_WM_LBUTTONDOWN")
    #MaxMem, 400 ; reading larger json files into objects overloads the default limit

; Global variables
    ; Variables
    Global DEBUG_MODE           := true
    , APP_NAME                  := "Droplogger"
    , APP_URL                   := "https://github.com/RB490/ahk-app-osrs-drop-logger"
    , GUI_LOG_MIN_DROP_SIZE     := 10
    , GUI_LOG_MAX_DROP_SIZE     := 80
    , GUI_LOG_MIN_ROW_LENGTH    := 1
    , GUI_LOG_MAX_ROW_LENGTH    := 25
    , GUI_LOG_MIN_TABLE_SIZE    := 1
    , GUI_LOG_ITEM_IMAGE_TYPES  := "Wiki Small|Wiki Detailed|RuneLite"

    ; Path variables
    , PATH_SCRIPT_SETTINGS          := A_ScriptDir "\Assets\Settings.json"
    , PATH_DATABASE_MOBS            := A_ScriptDir "\Assets\Database\Mobs.json"
    , PATH_DATABASE_ITEMS           := A_ScriptDir "\Assets\Database\Items.json"
    , PATH_DATABASE_PRICES          := A_ScriptDir "\Assets\Database\Prices.json"
    , PATH_DATABASE_CATEGORIES      := A_ScriptDir "\Assets\Database\Item categories.json"
    , PATH_RDT_DROPTABLE            := A_ScriptDir "\Assets\Database\RDT.json"
    , DIR_DATABASE_MOBS             := A_ScriptDir "\Assets\Database\Mobs"
    , DIR_MOB_IMAGES                := A_ScriptDir "\Assets\Images\Mobs"
    , DIR_GUI_ICONS                 := A_ScriptDir "\Assets\Images\Gui"
    , DIR_ITEM_IMAGES_ICONS         := A_ScriptDir "\Assets\Images\Items\Icons"
    , DIR_ITEM_IMAGES_DETAILED      := A_ScriptDir "\Assets\Images\Items\Detailed"
    , DIR_ITEM_IMAGES_RUNELITE      := A_ScriptDir "\Assets\Images\Items\RuneLite"
    
    ; Objects
    , SCRIPT_SETTINGS           := LoadSettings()
    , SELECTED_DROPS            := {}

    ; Class objects
    , P                         := new ClassGuiProgress(APP_NAME)
    , WIKI_SCRAPER              := new ClassWikiScraper
    , OSRS                      := new ClassOSRS
    , ITEM_PRICE                := new ClassItemPrices
    , DROP_LOG                  := new ClassDropLog
    , DROP_LOG_STATS            := new ClassDropLogStats
    , DROP_TABLE                := new ClassDropTable
    , DROP_CATEGORIES           := new ClassDropCategories
    , GUI_START                 := new ClassGuiStart
    , GUI_LOG                   := new ClassGuiLog
    , GUI_QUANTITY              := new ClassGuiQuantity
    , GUI_SETTINGS              := new ClassGuiSettings
    , GUI_ABOUT                 := new ClassGuiAbout
    , GUI_STATS                 := new ClassGuiStats
    

; Auto-execute section
    If DEBUG_MODE
        GoTo, debugScript
    GUI_START.Get()
    return

; Global hotkeys
    ~^s::
        If DEBUG_MODE and !A_IsCompiled
            reload
    return
    ~f1::
        If !DEBUG_MODE
            return
    return

; Subroutines
    debugScript:
        ; myDebugDropLogfile := A_ScriptDir "\Dev\myDebugDropLogfile.json"
        ; myDebugDropLogfile := "D:\Downloads\log.json"
        
        ; FileDelete, % myDebugDropLogfile
        ; FileAppend, {}, % myDebugDropLogfile

        ; SCRIPT_SETTINGS.previousMob := "Night Beast"
        ; SCRIPT_SETTINGS.previousLogFile := myDebugDropLogfile
        ; DROP_LOG.LoadFile(myDebugDropLogfile)
        ; DROP_LOG.StartTrip()

        ; DROP_TABLE.Get("Vorkath (Post-Quest)")
        ; DROP_TABLE.Get("Night Beast")
        ; DROP_TABLE.Get("Abyssal Demon (Standard)")

        ; RDT_Get()

        ; FileDelete, % "D:\Programming and projects\ahk-app-osrs-drop-logger\Assets\Database\Item categories.json"
        ; msgbox % OSRS.GetItemID("Abyssal Whip")
        ; GUI_LOG.Get()
        ; GUI_STATS.Get()
        ; GUI_START.Get()
        
        ; ITEM_PRICE._Update()

        obj := DROP_TABLE.Get("Goblin (level 2)")
        GUI_LOG.Get()

        ; _QPC("reset")
        ; OSRS                    := new ClassOSRS
        ; ITEM_PRICE                   := new ClassItemPrices
        ; ITEM_PRICE._Update()
        ; msgbox % _QPC()

        ; Msg("Info", "Auto-execute section", "End of Auto-execute section")
    return
    updateStats:
        GUI_STATS.Set(DROP_LOG.Stats.Get())
    return
    updateMobDb:
        OSRS._UpdateMobDatabase("silent")
    return
    disableTooltip:
        tooltip
    return
    menuHandler:
    return

; Includes
    #Include, %A_ScriptDir%\Includes
    #Include, Class Drop Log.ahk
    #Include, Class Drop Log Stats.ahk
    #Include, Class Drop Table.ahk
    #Include, Class Drop Categories.ahk
    #Include, Class Gui About.ahk
    #Include, Class Gui Log.ahk
    #Include, Class Gui Progress.ahk
    #Include, Class Gui Settings.ahk
    #Include, Class Gui Quantity.ahk
    #Include, Class Gui Start.ahk
    #Include, Class Gui Stats.ahk
    #Include, Class Item Prices.ahk
    #Include, Class OSRS.ahk
    #Include, Class Wiki Scraper.ahk
    #Include, Functions.ahk

; Libraries
    #Include, %A_ScriptDir%\Libraries
    #Include, _QPC.ahk
    #Include, AddCommas.ahk
    #Include, AutoXYWH.ahk
    #Include, Class Gui.ahk
    #Include, CommandFunctions.ahk
    #Include, DownloadToString.ahk
    #Include, FormatSeconds.ahk
    #Include, Gdip_All.ahk
    #Include, GuiButtonIcon.ahk
    #Include, IsPicture.ahk
    #Include, JSON.ahk
    #Include, LoadPictureType.ahk
    #Include, Msg.ahk
    #Include, ObjFullyClone.ahk
    #Include, ResConImg.ahk
    #Include, SetButtonIcon.ahk
    #Include, WinGetPos.ahk