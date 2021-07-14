class ClassGuiQuantity extends gui {
    /*
        param   'obj'               = {object}
                'obj'.name          = item name eg. 'Abyssal Whip'
                'obj'.quantity      = a single quantity divided by '-' eg. '500-900'
                                      or multiple quantities separated by '#' eg. '250#500-749#500-999'
        returns {object}
                {object}.name       = {string} input 'obj'.name
                {object}.high       = {integer} highest integer
                {object}.low        = {integer} lowest integer
                {object}.median     = {integer} median between lowest and highest integer
                {object}.integers   = {object} all integers
    */
    Load(obj) {
        output := {}
        integers := {}

        ; get integer array
        if InStr(obj.quantity, "#")
            arr := StrSplit(obj.quantity, "#")
        else
            arr := StrSplit(obj.quantity, "-")

        ; retrieve individual integers from array
        loop % arr.length() {
            int := arr[A_Index]
            
            If InStr(int, "-") {
                ints := StrSplit(int, "-")
                integers[ints[1]] := ""
                integers[ints[2]] := ""
            }
            else
                integers[int] := ""
        }

        this.name := output.name := obj.name
        this.id := obj.id
        output.integers := integers
        output.low := integers.MinIndex()
        output.high := integers.MaxIndex()
        output.median := (output.high - output.low) / 2 + output.low
        output.median := Round(output.median)
        return output
    }

    Set() {
        obj := {}
        obj.name := this.name
        obj.quantity := this.output
        SELECTED_DROPS.push(obj)
        GUI_LOG.Update()
    }

    ; param 'obj' = {object} retrieved by this.Get()
    Get(obj) {
        GUI_LOG.Disable()
        obj := this.Load(obj)

        ; destroy gui
        DetectHiddenWindows, On
        if WinExist(this.ahkid)
            this.Destroy()

        ; set title
        title := obj.name " : " obj.low " - " obj.high
        this.__New(title)

        ; set icon
        icoPath := GetGuiLogDropsImageType() "\" this.id ".png"
        ico := new LoadPictureType(icoPath,, 1, "#000000") ; last parameter color will be transparent, you might need to change this.
        this.SetIcon(ico.GetHandle())

        ; set properties
        this.Owner(GUI_LOG.hwnd)
        this.FadeInAnimation(false)
        this.Margin(0, 0)
        this.Options("-MinimizeBox")

        ; add controls
        buttons := obj.integers.count()
        maxRowLength := 5
        btnSize := 50

        this.Font("s29")
        this.Add("edit", "w" btnSize * (maxRowLength - 2) " h" btnSize " center number", obj.median)
        this.Font("s15")
        this.Add("button", "x+0 w" btnSize * 2 " h" btnSize, "Enter", this.BtnSubmit.Bind(this))

        for integer in obj.integers {
            If (rowLength = maxRowLength)
                rowLength := 0

            If (A_Index = 1) or !rowLength
                this.Add("button", "x0 w" btnSize " h" btnSize " ", integer, this.BtnInteger.Bind(this))
            else
                this.Add("button", "x+0 w" btnSize " h" btnSize "", integer, this.BtnInteger.Bind(this))

            rowLength++
        }

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, ClassGuiQuantityHotkeyEnter
        Hotkey, IfWinActive

        ; show
        this.Show("hide")
        WinGetPos, guiX, guiY, guiW, guiH, % this.ahkid
        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY
        this.Show("x" mouseX - (guiW / 2) " y" mouseY - (guiH / 2))

        ; close
        DetectHiddenWindows, Off
    }

    BtnInteger() {
        this.output := this.GuiControlGet("FocusV")
        this.Set()
        this.Close()
    }

    BtnSubmit() {
        this.output := this.GetText("edit1")
        this.Set()
        this.Close()
    }

    Close() {
        this.Destroy()
        GUI_LOG.Enable()
        GUI_LOG.Activate()
    }

    /*
        Example:
            debug := new GUI_QUANTITY.Debug(GUI_QUANTITY)
            debug.Get()
    */
    Class Debug {
        __New(parent) {
            this.parent := parent
        }

        Load() {
            obj := {}
            ; obj.quantity := "500-999"
            obj.quantity := "132#30#44#220#460#250-499#250#500-749#500-999"
            obj.name := "Abyssal Whip"
            this.parent.Load(obj)
        }

        Get() {
            integers := [123, 30, 44, 220, 460, 250, 9001]
            obj := {}
            obj.high := 999
            obj.median := 375
            obj.low := 250
            obj.integers := integers
            this.parent.Get(obj)
        }
    }
}

ClassGuiQuantityHotkeyEnter() {
    GUI_QUANTITY.BtnSubmit()
}