class class_gui_logger extends gui {
    Setup() {
        ; events

        ; properties
        this.SetDefault() ; set as default for GuiControl
        this.marginSize := 10

        ; controls
        this.Add("tab3", "h300", "")
        this._LoadDrops()

        DetectHiddenWindows, On ; for ControlGetPos
        ControlGetPos , tabX, tabY, tabW, tabH, SysTabControl321, % this.ahkid
        var = tabX = %tabX% %A_Tab% tabY = %tabY% %A_Tab% tabW = %tabW% %A_Tab% tabH = %tabH%
        this.Add("edit", "w" tabW, "<currently selected drops> " A_Tab var)

        this.Add("edit", "x" tabW + (this.marginSize * 2) " y" this.marginSize - 1 " w200 h" tabH, "<drop log>")

        ; show
        this.Show()
        ; this.Show("w450 h250")
    }

    _LoadDrops() {
        this.Margin(0, 0)
        dropSize := 27
        maxRowDrops := 10 ; after this amount of drops a new row is started

        loop % dropTable.obj.length() {
            tab := dropTable.obj[A_Index].tableTitle
            drops := dropTable.obj[A_Index].tableDrops

            ; add tab
            GuiControl,, SysTabControl321, % tab
            this.Tab(tab) ; Future controls are owned by the tab whose name starts with Name (not case sensitive).

            ; add drops
            rowDrops := 0
            loop % drops.length() {
                If (rowDrops = maxRowDrops)
                    rowDrops := 0

                dropImg := g_itemImgsPath "\" drops[A_Index].itemName ".png"
                
                totalItems++
                dropVar := "g_vLogGuiItem#" totalItems

                If (A_Index = 1)
                    this.AddGlobal("picture", "x+0 section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop
                else if !(rowDrops)
                    this.AddGlobal("picture", "xs ys+" dropSize " section w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; first drop of a new row
                else
                    this.AddGlobal("picture", "xp+" dropSize "  w" dropSize " h" dropSize " v" dropVar " border", dropImg) ; add normal drop

                rowDrops++
            }
        }

        this.Tab("") ; Future controls are not part of any tab control.
        this.Margin(this.marginSize, this.marginSize) ; restore margin size
    }
}