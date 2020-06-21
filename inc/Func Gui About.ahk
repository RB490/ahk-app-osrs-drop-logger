GuiAbout() {
    hwnd := LOG_GUI.hwnd
    gui about: -MinimizeBox +Owner%hwnd%

    gui about: font, s13
    gui about: add, text, , Github
    gui about: font

    url := PROJECT_WEBSITE
    gui about: add, link, gGuiAbout_BtnProjectWebsite, <a id="A">%url%</a>

    gui about: font, s13
    gui about: add, text, , Dependencies
    gui about: font

    gui about: add, text, , This program relies on information from various external sources and can (will) break when they change

    url := WIKI_API.url "/"
    gui about: add, link, gGuiAbout_BtnWiki, <a id="A">%url%</a>
    url := WIKI_API.url "/api.php"
    gui about: add, link, gGuiAbout_BtnBtnWikiApi, <a id="A">https://oldschool.runescape.wiki/api.php/</a>
    url := RUNELITE_API.apiHubUrl
    gui about: add, link, gGuiAbout_BtnRuneLiteApi, <a id="A">https://static.runelite.net/api/http-service/</a>

    gui about: show, , About
}

GuiAbout_BtnProjectWebsite:
    run % PROJECT_WEBSITE
return

GuiAbout_BtnWiki:
    run % WIKI_API.url "/"
return

GuiAbout_BtnBtnWikiApi:
    run % WIKI_API.url "/api.php"
return

GuiAbout_BtnRuneLiteApi:
    run % RUNELITE_API.apiHubUrl
return