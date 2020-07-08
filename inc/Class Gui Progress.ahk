Class ClassGuiProgress extends gui {
    Setup(text1 := "", bar1 := "", text2 := "", bar2 := "", text3 := "") {
        width := 300
        this.margin(5, 5)
        this.Font("", "Arial")


        If (text1) {
            this.Font("s15")
            this._text1 := this.add("text", "w" width " center", text1)
        }
        
        If (bar1)
            this._bar1 := this.add("progress", "w" width " h20 BackgroundWhite")
        
        If (text2) {
            this.Font("s12")
            this._text2 := this.add("text", "w" width " center", text2)
        }

        If (bar2)
            this._bar2 := this.add("progress", "w" width " h20 BackgroundWhite")

        If (text3) {
            this.Font("s12")
            this._text3 := this.add("text", "w" width " center", text3)
        }
        
        this.add("text", "w" width " center", "woiejgfpwoeijgoi")

        ; this.show("x0 y0 w250 h250", A_ThisFunc)
        ; this.show("x0 y0", A_ThisFunc)
        ; this.show()
        ; Gui % this.hwnd ":Show", x0 y0 w250 h250, title
/* 
        this.Control(, this._text1, "+25")
        loop 10 {
            this.Control(, this._progress, "+10")
            sleep 250
        }
         */
    }

    P(text1 := "", bar1 := "", text2 := "", bar2 := "", text3 := "") {
        ; If !this.IsVisible
            this.Setup(text1, bar1, text2, bar2, text3)
    }

    Title(title) {
        this.show(, title)
    }

    Close() {
        msgbox
    }
}

TestFunc(params*) {
    msgbox % params.length()
}