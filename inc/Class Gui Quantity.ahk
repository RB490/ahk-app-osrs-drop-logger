class ClassGuiQuantity extends gui {
    /*
        input = {object} item object from 'DROP_TABLE.GetDrop()' this method uses 
            input.quantity contains one wiki drop table quantity separated by -, or multiple quantities separated by '#'
            example: 132#30#44#220#460#250-499#250#500-749#500-999
        
        purpose =  sets this.obj eg:
            {
                "high": 999,
                "integersObj": [
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
    Get(input) {
        this.obj := {}
        this.obj.dropName := input.name

        If InStr(input, "#") ; multiple quantities
            arr := StrSplit(input.quantity, "#")
        else
            arr := StrSplit(input.quantity, "-") ; single quantity
        
        ; get lowest & highest range
        ints := {}
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
                ints.push(arr[A_Index])
        }

        this.obj.lowestQuantity := recordLow
        this.obj.highestQuantity := recordHigh
        middle := (recordHigh - recordLow) / 2 + recordLow
        middle := Round(middle)
         If (middle = 0)
            middle := ints[1]
        this.obj.medianQuantity := middle
        this.obj.integersObj := ints

        this.Setup()
        return this.output
    }

    Debug_Get() {
        integersObj := [123, 30, 44, 220, 460, 250, 9001]
        obj := {}
        obj.highestQuantity := 999
        obj.medianQuantity := 375
        obj.lowestQuantity := 250
        obj.integersObj := integersObj
        this.obj := obj
        this.Setup()
        return this.output
    }

    Setup() {
        LOG_GUI.Disable()

        ; recreate window if it already exists
        if (WinExist(this.ahkid))
            this.Destroy()
        guiName := this.obj.dropName A_Space
        If (this.obj.lowestQuantity)
            guiName := guiName this.obj.lowestQuantity " - " this.obj.highestQuantity
        this.__New(guiName)

        ; events
        this.Events["_HotkeyEnter"] := this.BtnSubmit.Bind(this)
        this.Events["_HotkeyEscape"] := this.Close.Bind(this)
        this.Events["_BtnEnter"] := this.BtnSubmit.Bind(this)

        ; properties
        this.Owner(LOG_GUI.hwnd)
        this.Margin(0, 0)
        this.Options("+toolwindow  +labelquantityGui_")
        totalButtons := this.obj.integersObj.length()
        maxRowLength := 5
        controlSize := 50

        ; controls
        this.Font("s29")
        this.Add("edit", "w" controlSize * (maxRowLength - 2) " h" controlSize " center number", this.obj.medianQuantity)
        this.Font("s15")
        this.Add("button", "x+0 w" controlSize * 2 " h" controlSize " gquantityGui_BtnHandler", "Enter")

        loop % totalButtons {
            If (rowLength = maxRowLength)
                rowLength := 0

            If (A_Index = 1) or !(rowLength)
                this.Add("button", "x0 w" controlSize " h" controlSize " gquantityGui_BtnHandler", this.obj.integersObj[A_Index])
            else
                this.Add("button", "x+0 w" controlSize " h" controlSize " gquantityGui_BtnHandler", this.obj.integersObj[A_Index])

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

        ; on closing
        LOG_GUI.Enable()
        WinActivate, % LOG_GUI.ahkid
    }

    ; input = {integer}
    BtnIntegerHandler(input) {
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

    ; call specific method if a integer button is pressed
    If OutputControlText is Integer
        QUANTITY_GUI.BtnIntegerHandler(OutputControlText)

    ; call the class's method
    for a, b in ClassGuiQuantity.Instances 
		if (a = A_Gui+0)
			b["Events"]["_Btn" OutputControlText].Call()
return

quantityGui_HotkeyEnter:
    ; call the class's method
    for a, b in ClassGuiQuantity.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEnter"].Call()
return

quantityGui_Close:
quantityGui_HotkeyEscape:
    ; call the class's method
    for a, b in ClassGuiQuantity.Instances 
		if (a = WinExist("A")+0) ; if instance gui hwnd is identical to currently active window hwnd
			b["Events"]["_HotkeyEscape"].Call()
return