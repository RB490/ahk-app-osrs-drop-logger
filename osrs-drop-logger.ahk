; Script options
    Menu, Tray, MainWindow ; open debug window for compiled script
    SetBatchLines, -1
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    CoordMode, Mouse, Screen
    SetBatchLines, -1

; Global variables
    Global DEBUG_MODE           := true
    , APP_NAME                  := A_ScriptName
    ; , PATH_DATABASE_MOBLIST     := A_ScriptDir "\Assets\Database\MobList"
    , P                         := new ClassGuiProgress(APP_NAME)
    , PATH_DATABASE_MOBS        := A_ScriptDir "\Assets\Mob database"
    , MOB_DB                    := new ClassMobDatabase

; Auto-execute section

    Msg("Info", "Auto-execute section", "End of Auto-execute section")
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
    #Include, Class Mob Database.ahk

; Libraries
    #Include, %A_ScriptDir%\Libraries
    #Include, _QPC.ahk
    #Include, Class Gui.ahk
    #Include, CommandFunctions.ahk
    #Include, DownloadToString.ahk
    #Include, JSON.ahk
    #Include, Msg.ahk