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
    , P                         := new ClassGuiProgress(APP_NAME)
    , PATH_DATABASE_MOBS        := A_ScriptDir "\Assets\Database\Mobs database.json"
    , DIR_DATABASE_MOBS         := A_ScriptDir "\Assets\Database\Mobs"
    , MOB_DB                    := new ClassMobDatabase
    , GUI_START                 := new ClassGuiStart

; Auto-execute section
    ; GUI_START.Get()

    myObj := MOB_DB.GetList()
    msgbox % json.dump(myObj,,2)

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

; Libraries
    #Include, %A_ScriptDir%\Libraries
    #Include, _QPC.ahk
    #Include, Class Gui.ahk
    #Include, CommandFunctions.ahk
    #Include, DownloadToString.ahk
    #Include, GuiButtonIcon.ahk
    #Include, JSON.ahk
    #Include, Msg.ahk
    #Include, SetButtonIcon.ahk