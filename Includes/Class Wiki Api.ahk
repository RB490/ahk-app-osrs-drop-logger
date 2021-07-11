/*
    ClassWikiApi
        Purpose
            Handle all data retrievals from the wiki

    Misc/Temp
        WIKI_API.img.GetItemImages(itemName, 50)
        WIKI_API.img.GetMobImage(mobName)

    Sources
        Categories
            https://oldschool.runescape.wiki/api.php?action=query&list=categorymembers&cmlimit=500&format=json&cmtitle=Category:Runes
            https://www.mediawiki.org/wiki/API:Categorymembers
            https://oldschool.runescape.wiki/api.php?action=help&modules=query
            https://www.osrsbox.com/blog/2018/12/12/scraping-the-osrs-wiki-part1/#extract-all-categories

        Images
            https://www.mediawiki.org/wiki/API:Allimages
            https://www.mediawiki.org/wiki/API:Images

            https://oldschool.runescape.wiki/api.php?action=help&modules=query%2Bimageinfo
            Seems wiki can scale images

            Getting images for an item
                1. list images on page
                    https://oldschool.runescape.wiki/api.php?action=help&modules=query%2Bimages
                    https://oldschool.runescape.wiki/api.php?action=query&generator=images&titles=Ashes
                
                2. use image name to find the url
                    https://oldschool.runescape.wiki/api.php?action=help&modules=query%2Bimageinfo
                    https://oldschool.runescape.wiki/api.php?action=query&titles=File:Ashes_detail.png&prop=imageinfo&iiprop=url

            'titles' parameter: Maximum number of values is 50 (500 for clients allowed higher limits). Source: https://www.mediawiki.org/wiki/API:Query

    Info
        Special characters
            Convert + to %2B

*/


Class ClassWikiApi {
    baseUrl := "https://oldschool.runescape.wiki/api.php?"
    baseQuery := "action=query&format=json"

    __New() {
        ; msgbox % A_ThisFunc
    }

    _ConvertStrangeCharactersToWikiFormat(string) {
        return StrReplace(string, "+", "%2b")
    }

    _GetUrl(url) {
        outputInfo := A_ThisFunc "`n`n------------------------------`n`n"
        outputInfo.= "Input(Url)`n`n" url "`n`n------------------------------`n`n"
        
        url := this._ConvertStrangeCharactersToWikiFormat(url)
        outputInfo.= "Converted Input(Url)`n`n" url "`n`n------------------------------`n`n"

        ; call api
        result := DownloadToString(url)
        outputInfo.= "result`n`n" result "`n`n------------------------------`n`n"
        

        ; return output
        output := json.load(result)
        outputInfo.= "output`n`n" json.dump(output,,2) "`n`n------------------------------`n`n"

        return output
    }

    GetItemUrls(itemName) {
        ; -------------------------------------------------------- one api call

        url := this.baseUrl this.baseQuery "&prop=imageinfo&iiprop=url&titles=File:" itemName ".png|File:" itemName "_detail.png"
        obj := this._GetUrl(url).query.pages
        
        ; check valid amount of pages were returned
        If (obj.count() > 2)
            Msg("Info", A_ThisFunc, "Unexpectedly, more than 2 pages were found in api call")

        ; fetch information
        output := []
        for page in obj {
            title := obj[page].title
            url := obj[page].imageinfo.pop().url

            If InStr(title, "detail")
                output["detail"] := url
            else
                output["icon"] := url

        }
        return output
        
        ; -------------------------------------------------------- two api calls

        detailUrl := this.baseUrl this.baseQuery "&prop=imageinfo&iiprop=url&titles=File:Ashes_detail.png"
        iconUrl := this.baseUrl this.baseQuery  "&prop=imageinfo&iiprop=url&titles=File:Ashes.png"
        urls := {"detail": detailUrl, "icon": iconUrl}

        output := []
        for type, url in urls {
            ; get api info
            obj := this._GetUrl(url).query.pages

            ; assuming there is only one page result
            obj := obj.pop() ; get page
            itemUrl := obj.imageinfo.pop().url ; get imageinfo url
            
            output[type] := itemUrl
        }
        return output
    }
}