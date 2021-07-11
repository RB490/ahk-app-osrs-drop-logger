class ClassGuiAbout extends gui {
    Get() {
        ; set icon
        icoPath := DIR_GUI_ICONS "\osrs_icons\Quest_start_icon.png"
        ico := new LoadPictureType(icoPath,, 1, "#000000") ; last parameter color will be transparent, you might need to change this.
        this.SetIcon(ico.GetHandle())
        
        this.Owner(GUI_LOG.hwnd)

        this.Font("s13")
        this.Add("text", , "Project Website")
        this.Font("")

        url := APP_URL
        html = <a id="A">%url%</a>
        this.Add("link", , html, this.BtnLink.Bind(this))
        
        this.Font("s13")
        this.Add("text", , "Dependencies")
        this.Font("")

        this.Add("text", , "This program relies on information from various external sources and can (will) break when they change")

        url := "https://oldschool.runescape.wiki/api.php"
        html = <a id="A">%url%</a>
        this.Add("link", , html, this.BtnLink.Bind(this))

        url := "https://github.com/osrsbox/osrsbox-db"
        html = <a id="A">%url%</a>
        this.Add("link", , html, this.BtnLink.Bind(this))

        this.Show()
    }

    BtnLink() {
        html := this.GuiControlGet("FocusV")
        needleA1 = <a id="A">
        needleA2 = </a>
        html := StrReplace(html, needleA1)
        html := StrReplace(html, needleA2)
        run % html
    }
}