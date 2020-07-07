#SingleInstance, force
global g_output



g_output = If !FileExist(A_ScriptDir "\res") { `n
putOut("SplashTextOn, 450, 150, %A_ScriptName%, Extracting files into %A_ScriptDir%\res")

putOut("FileCreateDir, %A_ScriptDir%\res")
loop, files, % A_ScriptDir "\res\*.*", FDR
{
    SplitPath, A_LoopFileFullPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
    
    relativePath := StrReplace(A_LoopFileFullPath, A_ScriptDir)

    If !OutExtension
        putOut("FileCreateDir, %A_ScriptDir%" relativePath)
    else
        putOut("FileInstall, " A_LoopFileFullPath ", %A_ScriptDir%" relativePath ", 0")
        
}

putOut("SplashTextOff")
g_output .= "}"
FileDelete, % A_ScriptDir "\FileInstall.txt"
FileAppend, % g_output, % A_ScriptDir "\FileInstall.txt"
exitapp
return

putOut(in) {
    g_output .= in "`n" 
}

~^s::reload