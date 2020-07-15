Msg(type, func, msg) {
    switch type {
        case "Info": id := 4160
        case "InfoYesNo": id := 36
        case "Error": { 
            id := 16
            If DEBUG_MODE {
                msg .= "`n`nReloading.."
            } else {
                msg .= "`n`nCheck: " PROJECT_WEBSITE
                msg .= "`n`nClosing.."
            }
        }
        default: {
            msgbox, 4160, , % A_ThisFunc ": Unhandled type specified. `n`nReloading.."
            reload
        }
    }

    If DEBUG_MODE
        msgbox, % id, % func, % msg
    else
        msgbox, % id, % APP_NAME, % msg

    If (type = "Error") {
        If DEBUG_MODE
            reload
        else
            exitapp
    }
}