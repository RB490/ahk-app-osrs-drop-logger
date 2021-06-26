; scales image and centers together with text
; example SetButtonIcon(_MAIN_GUI_BTN_LOG, path, 1, 44)
SetButtonIcon(hButton, File, Index, Size := 16) {
    hIcon := LoadPicture(File, "h" . Size . " Icon" . Index, _)
    SendMessage 0xF7, 1, %hIcon%,, ahk_id %hButton% ; BM_SETIMAGE
}