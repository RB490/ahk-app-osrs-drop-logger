#SingleInstance, Force
SetWorkingDir % A_ScriptDir

; recreate compile dir
If FileExist(A_ScriptDir "\bin") {
    FileRemoveDir, % A_ScriptDir "\bin", 1
    If (ErrorLevel) {
        msgbox FileRemoveDir ErrorLevel = %ErrorLevel%`n`nClosing..
        exitapp
    }
}
FileCreateDir, % A_ScriptDir "\bin"

; cleanup resource folder
FileDelete % A_ScriptDir "\res\monsters-complete.json"

; create file install list
run % A_ScriptDir "\Create FileInstall.ahk"

; compile script
SplitPath, A_AhkPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
compExe := OutDir "\Compiler\Ahk2Exe.exe"
run %compExe% /in "OSRS Drop Logger.ahk" /out "%A_ScriptDir%\bin\OSRS Drop Logger.exe" /icon "app.ico"

; cleanup file install list
FileDelete % A_ScriptDir "\FileInstall.txt"
exitapp