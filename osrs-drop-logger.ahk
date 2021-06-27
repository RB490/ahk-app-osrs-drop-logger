; Script options
    Menu, Tray, MainWindow ; open debug window for compiled script
    SetBatchLines, -1
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    CoordMode, Mouse, Screen
    SetBatchLines, -1
    OnExit("ExitFunc")

; Global variables
    ; Variables
    Global DEBUG_MODE           := true
    , APP_NAME                  := A_ScriptName
    , PATH_SCRIPT_SETTINGS      := A_ScriptDir "\Assets\Settings.json"
    , PATH_DATABASE_MOBS        := A_ScriptDir "\Assets\Database\Mobs database.json"
    , DIR_DATABASE_MOBS         := A_ScriptDir "\Assets\Database\Mobs"
    , DIR_MOB_IMAGES            := A_ScriptDir "\Assets\Images\Mobs"
    
    ; Objects
    , SCRIPT_SETTINGS           := LoadSettings()

    ; Class objects
    , P                         := new ClassGuiProgress(APP_NAME)
    , MOB_DB                    := new ClassMobDatabase
    , GUI_START                 := new ClassGuiStart
    , WIKI_API                  := new ClassApiWiki

; Auto-execute section
    ; GUI_START.Get()

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
    #Include, Class Gui Progress.ahk
    #Include, Class Gui Start.ahk
    #Include, Class Mob Database.ahk
    #Include, Class Api Wiki.ahk
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
    #Include, ResConImg.ahk
    #Include, SetButtonIcon.ahk