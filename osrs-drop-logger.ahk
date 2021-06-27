; Script options
    Menu, Tray, MainWindow ; open debug window for compiled script
    SetBatchLines, -1
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    CoordMode, Mouse, Screen
    SetBatchLines, -1
    OnExit("ExitFunc")
    #MaxMem, 400 ; reading larger json files into objects overloads the default limit

; Global variables
    ; Variables
    Global DEBUG_MODE           := true
    , APP_NAME                  := A_ScriptName
    , PATH_SCRIPT_SETTINGS      := A_ScriptDir "\Assets\Settings.json"
    , PATH_DATABASE_MOBS        := A_ScriptDir "\Assets\Database\Mobs database.json"
    , PATH_DATABASE_ITEMS       := A_ScriptDir "\Assets\Database\Items database.json"
    , DIR_DATABASE_MOBS         := A_ScriptDir "\Assets\Database\Mobs"
    , DIR_MOB_IMAGES            := A_ScriptDir "\Assets\Images\Mobs"
    , DIR_GUI_ICONS             := A_ScriptDir "\Assets\Images\Gui"
    , DIR_ITEM_IMAGES_ICONS     := A_ScriptDir "\Assets\Images\Items\Icons"
    , DIR_ITEM_IMAGES_DETAILED  := A_ScriptDir "\Assets\Images\Items\Detailed"
    
    ; Objects
    , SCRIPT_SETTINGS           := LoadSettings()

    ; Class objects
    , P                         := new ClassGuiProgress(APP_NAME)
    , WIKI_API                  := new ClassApiWiki
    , ITEM_DB                   := new ClassDatabaseItems
    , MOB_DB                    := new ClassDatabaseMobs
    , DROP_LOG                  := new ClassDropLog
    , DROP_TABLE                := new ClassDropTable
    , GUI_START                 := new ClassGuiStart
    , GUI_LOG                   := new ClassGuiLog

; Auto-execute section
    ; download mob images


    ; rename mob names to id's
    ; mobs := MOB_DB.GetList()
    ; for id, mob in mobs {
    ;     sourcePath := DIR_MOB_IMAGES "\" mob ".png"
    ;     targetPath := DIR_MOB_IMAGES "\" id ".png"

    ;     FileMove, % sourcePath, % targetPath
        ; msgbox % sourcePath "`n`n" targetPath
    ; }
        ; DROP_TABLE.Get(mob)
    
    ; DROP_TABLE.Get("Vorkath")
    GUI_START.Get()
    ; GUI_LOG.Get()


    ; Msg("Info", "Auto-execute section", "End of Auto-execute section")
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

; Includes
    #Include, %A_ScriptDir%\Includes
    #Include, Class Api Wiki.ahk
    #Include, Class Database Items.ahk
    #Include, Class Database Mobs.ahk
    #Include, Class Drop Log.ahk
    #Include, Class Drop Table.ahk
    #Include, Class Gui Log.ahk
    #Include, Class Gui Progress.ahk
    #Include, Class Gui Start.ahk
    #Include, Functions.ahk

; Libraries
    #Include, %A_ScriptDir%\Libraries
    #Include, _QPC.ahk
    #Include, Class Gui.ahk
    #Include, CommandFunctions.ahk
    #Include, DownloadToString.ahk
    #Include, Gdip_All.ahk
    #Include, GuiButtonIcon.ahk
    #Include, IsPicture.ahk
    #Include, JSON.ahk
    #Include, Msg.ahk
    #Include, ObjFullyClone.ahk
    #Include, ResConImg.ahk
    #Include, SetButtonIcon.ahk
    #Include, WinGetPos.ahk