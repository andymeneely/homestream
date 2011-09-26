'********************************
'*                              *
'* Andy's hacktastic HomeStream *
'*                              *
'********************************

Sub Main()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'prepare the screen for display and get ready to begin
    screen=preShowPosterScreen("", "")
    if screen=invalid then
        print "unexpected error in preShowPosterScreen"
        return
    end if
 
    'set to go, time to get started
    showPosterScreen(screen)
    
    'shortcut straight to a hard-coded video
    'video = ""
    'print "Shortcutting straight to video: ";video
    'displayVideo("")
End Sub

'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'*************************************************************
Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "15"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/Logo_Overhang_SD43.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/Logo_Overhang_HD.png"
    
    app.SetTheme(theme)

End Sub

'******************************************************
'** Perform any startup/initialization stuff prior to 
'** initially showing the screen.  
'******************************************************
Function preShowPosterScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if
    screen.SetListStyle("flat-category")
    return screen
End Function

'******************************************************
'** Display the poster screen and wait for events from 
'** the screen. The screen will show retreiving while
'** we fetch and parse the feeds for the show posters
'******************************************************
Function showPosterScreen(screen As Object) As Integer

    categoryList = getCategoryList()
    screen.SetListNames(categoryList)
    screen.SetContentList(getShowsForCategoryItem(categoryList[0]))
    screen.Show()

    videos = getVideoList()

    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            print "showPosterScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
            if msg.isListFocused() then
                'get the list of shows for the currently selected item
                screen.SetContentList(videos)
                print "list focused | current category = "; msg.GetIndex()
            else if msg.isListItemFocused() then
                print"list item focused | current show = "; msg.GetIndex()
            else if msg.isListItemSelected() then
                print "list item selected | show index = "; msg.GetIndex();"show: ";videos[msg.GetIndex()]
                showSpringboardScreen(videos[msg.GetIndex()].ShortDescriptionLine1)
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
End Function

'*************************************************************
'** showSpringboardScreen()
'*************************************************************
Function showSpringboardScreen(videoName as Object) As Boolean
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    print "showSpringboardScreen showing ";videoName
    
    screen.SetMessagePort(port)
    screen.AllowUpdates(false)
    
    item = { ContentType:"episode"
               SDPosterUrl:"file://pkg:/images/video.png"
               HDPosterUrl:"file://pkg:/images/video.png"
               IsHD:False
               HDBranded:False
               ShortDescriptionLine1:""
               ShortDescriptionLine2:""
               Description:""
               Rating:"NR"
               StarRating:"80"
               Length:1972
               Categories:[]
               Title:videoName
               }
               
    if item <> invalid and type(item) = "roAssociativeArray"
        screen.SetContent(item)
    endif

    screen.SetDescriptionStyle("generic") 'audio, movie, video, generic
                                        ' generic+episode=4x3,
    screen.ClearButtons()
    screen.AddButton(1,"Play")
    screen.AddButton(2,"Go Back")
    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)
    screen.Show()

    downKey=3
    selectKey=6
    
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSpringboardScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    if msg.GetIndex() = 1
                         print "Going to display video: ";videoName
                         displayVideo(videoName)
                    else if msg.GetIndex() = 2
                         return true
                    endif
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        else 
            print "wrong type.... type=";msg.GetType(); " msg: "; msg.GetMessage()
        endif
    end while
    return true
End Function


'*************************************************************
'** Actually show the video
'*************************************************************
Function displayVideo(videoName as Object)
    print "Displaying video: ";videoName
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)

    'Swap the commented values below to play different video clips...
    
    urls = ["http://192.168.0.3/videos/" + videoName]
    print "Using URL: ";urls
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = [0]
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = ["SD"]
    videoclip.StreamFormat = "mp4"
    videoclip.Title = videoName
    
    video.SetContent(videoclip)
    video.show()

    lastSavedPos   = 0
    statusInterval = 10 'position must change by more than this number of seconds before saving

    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 10000
                    
                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while
End Function

'**************************************************************
'** Return the list of categories to display in the filter
'** banner. The result is an roArray containing the names of 
'** all of the categories. All just static data for the example.
'***************************************************************
Function getCategoryList() As Object
    categoryList = CreateObject("roArray", 10, true)
    categoryList = [ "Videos", "Music"]
    return categoryList
End Function

'********************************************************************
'** Given the category from the filter banner, return an array 
'** of ContentMetaData objects (roAssociativeArray's) representing 
'** the shows for the category. For this example, we just cheat and
'** create and return a static array with just the minimal items
'** set, but ideally, you'd go to a feed service, fetch and parse
'** this data dynamically, so content for each category is dynamic
'********************************************************************
Function getShowsForCategoryItem(category As Object) As Object
    print "getting shows for category "; category
    showList = [{ ShortDescriptionLine1:"Nothing here yet" }]
    if category = "Videos"
        showList = getVideoList() 
    end if
    return showList
End Function

'******************************************************************
'** Given a connection object for a category feed, fetch,
'** parse and build the tree for the feed.  the results are
'** stored hierarchically with parent/child relationships
'** with a single default node named Root at the root of the tree
'******************************************************************
Function getVideoList() As Dynamic

    http = NewHttp("http://192.168.0.3/videos/feed.php")

    print "url: "; http.Http.GetUrl()

    rsp = http.GetToStringWithRetry()
    
    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
         print "Can't parse feed"
        return invalid
    endif
    
    if xml.videos = invalid then
        print "no videos tag"
        return invalid
    endif

    print "begin video node parsing"
    xmllist = xml.GetNamedElements("video")

    video = []
    for each v in xmllist
        print "Adding file: ";v@file
        video.Push({
            ShortDescriptionLine1: v@file,
            URL: v@file,
        })
    next
    
    print "done video node parsing"
    return video
End Function
