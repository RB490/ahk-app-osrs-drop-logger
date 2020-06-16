; Script options
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    SetBatchLines, -1
    OnExit("ExitFunc")
    OnMessage(0x201, "OnWM_LBUTTONDOWN")

; Global vars
    global  g_debug             := true
    global  g_path_itemImages   := A_ScriptDir "\res\img\items"
    global  g_path_itemIds      := A_ScriptDir "\res\itemIds.json"
    global  g_selectedDrops     := {}
    global  wiki                := new class_wiki
    global  runeLite            := new class_runeLite
    global  logGui              := new class_gui_logger("Log Gui")
    global  dropTable           := new class_dropTable
    global  dropLog             := new class_dropLog
    global  settings            := {}

; Auto-execute
    FileCreateDir, % g_path_itemImages
    FileRead, Input, % A_ScriptDir "\settings.json"
    If (Input) and !(Input = "{}") and !(Input = """" """") ; double quotes
        settings := json.load(Input)

    dropTable.GetDrops("Black_demon")
    dropLog.Load("some input")
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

; Includes
    #Include, <JSON>
    #Include, <class gui>
    #Include, <CommandFunctions>
    #Include, %A_ScriptDir%\inc
    #Include Class DropTable.ahk
    #Include Class DropLog.ahk
    #Include Class RuneLite.ahk
    #Include Class Gui Logger.ahk
    #Include Class Wiki.ahk
    #Include Functions.ahk