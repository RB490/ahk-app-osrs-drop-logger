class class_gui_quantity extends gui {
    /*
        input = {object} item object from 'dropTable.GetDrop()' this method uses 
            input.quantity which contains one or multiple wiki drop table quantities separated by '#'
            example: 132#30#44#220#460#250-499#250#500-749#500-999
    */
    Get(input) {
        this.inputObj := input
        arr := StrSplit(this.inputObj.quantity, "#")
        objInts := {}
        
        ; get lowest & highest range
        loop % arr.length() {
            LoopField := arr[A_Index]

            If InStr(LoopField, "-") {
                low := SubStr(LoopField, 1, InStr(LoopField, "-") - 1)
                high := SubStr(LoopField, InStr(LoopField, "-") + 1)

                If (low < recordLow) or !(recordLow)
                    recordLow := low

                If (high > recordHigh)
                    recordHigh := high

                arr.Delete(A_Index)
            }
            else
                objInts.push(arr[A_Index])
        }

        obj := {}
        obj.low := recordLow
        obj.high := recordHigh
        obj.middle := (obj.high - obj.low) / 2 + obj.low
        obj.middle := Round(obj.middle)
        obj.integers := objInts

        this.Setup(obj)
        return this.output
    }
    

    /*
    ; obj = {object} containing information received by Get() method. example:
        {
            "high": 999,
            "integers": [
                "132",
                "30",
                "44",
                "220",
                "460",
                "250"
            ],
            "low": 250
        }
    */
    Setup(obj:="") {
        If !(obj) {
            integers := [123, 30, 44, 220, 460, 250, 9001]
            obj := {}
            obj.high := 999
            obj.middle := 375
            obj.low := 250
            obj.integers := integers
        }

        ; disable log gui
        logGui.Disable()

        ; recreate window if it already exists
        if (WinExist(this.ahkid))
            this.Destroy()
        guiName := this.inputObj.name A_Space
        If (obj.low)
            guiName := guiName obj.low " - " obj.high
        this.__New(guiName)

        this.Owner(logGui.hwnd)

        ; events
        this.Events["_HotkeyEnter"] := this.BtnSubmit.Bind(this)
        this.Events["_HotkeyEscape"] := this.Close.Bind(this)
        this.Events["_BtnEnter"] := this.BtnSubmit.Bind(this)

        ; properties
        this.Margin(0, 0)
        this.Options("+toolwindow  +labelquantityGui_")
        totalButtons := obj.integers.length()
        maxRowLength := 5
        controlSize := 50

        ; controls
        this.Font("s29")
        this.Add("edit", "w" controlSize * (maxRowLength - 2) " h" controlSize " center number", obj.middle)
        this.Font("s15")
        this.Add("button", "x+0 w" controlSize * 2 " h" controlSize " gquantityGui_BtnHandler", "Enter")

        loop % totalButtons {
            If (rowLength = maxRowLength)
                rowLength := 0

            If (A_Index = 1) or !(rowLength)
                this.Add("button", "x0 w" controlSize " h" controlSize " gquantityGui_BtnHandler", obj.integers[A_Index])
            else
                this.Add("button", "x+0 w" controlSize " h" controlSize " gquantityGui_BtnHandler", obj.integers[A_Index])

            rowLength++
        }

        ; reset variables
        this.output := ""

        ; hotkeys
        Hotkey, IfWinActive, % this.ahkid
        Hotkey, Enter, quantityGui_HotkeyEnter
        Hotkey, Escape, quantityGui_HotkeyEscape
        Hotkey, IfWinActive

        ; show
        DetectHiddenWindows, On
        this.Show("hide")
        WinGetPos, guiX, guiY, guiW, guiH, % this.ahkid
        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY
        xPos := mouseX - (guiW / 2)
        yPos := mouseY - (guiH / 2)
        this.Show("x" mouseX - (guiW / 2) " y" mouseY - (guiH / 2))
        DetectHiddenWindows, Off
        WinWaitClose, % this.ahkid
        logGui.Enable()
        WinActivate, % logGui.ahkid
    }

    ; input = {integer}
    IntegerHandler(input) {
        this.output := input
        this.Destroy()
    }

    BtnSubmit() {
        this.output := this.GetText("edit1")
        this.Close()
    }

    Close() {
        this.Destroy()
    }
}

quantityGui_BtnHandler:
    ; get active button text without spaces
    ControlGetFocus, OutputControl, A
    ControlGetText, OutputControlText, % OutputControl, A
    OutputControlText := StrReplace(OutputControlText, A_Space)

    If OutputControlText is Integer
        quantityGui.IntegerHandler(OutputControlText)

    ; call the class's method
    for a, b in class_gui_quantity.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
return

quantityGui_HotkeyEnter:
    ; call the class's method
    for a, b in class_gui_quantity.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
return

quantityGui_Close:
quantityGui_HotkeyEscape:
    ; call the class's method
    for a, b in class_gui_quantity.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEscape"].Call()
return