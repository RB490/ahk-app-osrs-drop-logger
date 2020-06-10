; Script options
    #SingleInstance, Force
    #NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
    OnExit("ExitFunc")

; Global vars
    global  g_debug         := true
    global  g_itemImgsPath  := A_ScriptDir "\res\img\items"
    global  wiki            := new class_wiki
    global  logGui          := new class_gui_logger("Log Gui")
    global  dropTable       := new class_dropTable
    global  settings        := {}

; Auto-execute
    FileCreateDir, % g_itemImgsPath
    FileRead, Input, % A_ScriptDir "\settings.json"
    If (Input) and !(Input = "{}") and !(Input = """" """") ; double quotes
        settings := json.load(Input)
    
    dropTable.GetDrops("Black_demon")
    logGui.Setup()
return

; Global hotkeys
    ~^s::reload

; Includes
    #Include, <JSON>
    #Include, <class gui>
    #Include, %A_ScriptDir%\inc
    #Include Class DropTable.ahk
    #Include Class Gui Logger.ahk
    #Include Class Wiki.ahk
    #Include Functions.ahk