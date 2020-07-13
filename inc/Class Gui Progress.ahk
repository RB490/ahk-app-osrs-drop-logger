Class ClassGuiProgress extends gui {
    Get(title := "", text1 := "", bar1 := "", text2 := "", bar2 := "", text3 := "") {
        width := 350
        SplitPath, A_ScriptName, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
        this.__New(OutNameNoExt ":" A_Space title "()")
        this.margin(5, 5)
        this.Options("-MinimizeBox")

        If (text1) {
            this.Font("s15")
            this._text1 := this.add("text", "w" width " center", text1 "...")
        }
        
        If (bar1)
            this._bar1 := this.add("progress", "w" width " h20 Range0-" bar1 " BackgroundWhite")
        
        If (text2) {
            this.Font("s12")
            this._text2 := this.add("text", "w" width " center", text2)
        }

        If (bar2)
            this._bar2 := this.add("progress", "w" width " h20 Range0-" bar2 " BackgroundWhite")

        If (text3) {
            this.Font("s12")
            this._text3 := this.add("text", "w" width " center", text3)
        }

        this.Show()
    }

    T(title) {
        this.show(, title)
    }

    T1(text1 = "") {
        this.Control(, this._text1, text1)
    }

    B1(input := "") {
        If IsInteger(input) {
            this.Control("+Range0-" input, this._bar1)
            return
        }

        this.Control(, this._bar1, "+1")
    }

    T2(text2 = "") {
        this.Control(, this._text2, text2)
    }

    B2() {
        this.Control(, this._bar2, "+1")
    }

    T3(text3 = "") {
        this.Control(, this._text3, text3)
    }

    Close() {
        msgbox, 36, , % A_ThisFunc ": Are you sure you want to quit?"
        IfMsgBox, No
            return true ; https://www.autohotkey.com/docs/commands/Gui.htm#GuiClose
        exitapp
    }
}