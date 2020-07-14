#SingleInstance, force
global g_output

Out("FileCreateDir, %A_ScriptDir%\res")
loop, files, % A_ScriptDir "\res\*.*", FDR
{
    SplitPath, A_LoopFileFullPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
    
    relativePath := StrReplace(A_LoopFileFullPath, A_ScriptDir)

    If !OutExtension
        Out("FileCreateDir, %A_ScriptDir%" relativePath)
    else
        Out("FileInstall, " A_LoopFileFullPath ", %A_ScriptDir%" relativePath ", 0")
}

Out("SplashTextOff")
FileDelete, % A_ScriptDir "\FileInstall.ahk"
FileAppend, % g_output, % A_ScriptDir "\FileInstall.ahk"
exitapp
return

Out(in) {
    g_output .= in "`n" 
}

~^s::reload