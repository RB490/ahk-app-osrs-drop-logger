Msg(type, funcString, msgString) {
    switch type {
        case "Info": id := 4160
        case "InfoYesNo": id := 36
        case "Error": { 
            id := 16
            If DEBUG_MODE {
                msgString .= "`n`nReloading.."
            } else {
                msgString .= "`n`nCheck: " PROJECT_WEBSITE
                msgString .= "`n`nClosing.."
            }
        }
        default: {
            msgbox, 4160, , % A_ThisFunc ": Unhandled type specified. `n`nReloading.."
            reload
        }
    }

    If DEBUG_MODE
        msgbox, % id, % funcString, % msgString
    else
        msgbox, % id, % APP_NAME, % msgString

    If (type = "Error") {
        If DEBUG_MODE
            reload
        else
            exitapp
    }
}