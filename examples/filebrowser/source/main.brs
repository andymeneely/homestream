' ********************************************************************
' ********************************************************************
' **  Roku File Browser Channel (BrightScript)
' **
' **  January 2010
' **  Copyright (c) 2010 Roku Inc. All Rights Reserved.
' ********************************************************************
' ********************************************************************

Sub Main()
    m.port = CreateObject("roMessagePort")
    m.filesystem = CreateObject("roFilesystem")
    m.filesystem.SetMessagePort(m.port)
    app = CreateObject("roAppManager")
    app.SetTheme({
        OverhangOffsetSD_X: "64"
        OverhangOffsetSD_Y: "40"
        OverhangSliceSD: "pkg:/images/overhang-background-sd.png"
        OverhangLogoSD:  "pkg:/images/logo-sd.png"

        OverhangOffsetHD_X: "108"
        OverhangOffsetHD_Y: "60"
        OverhangSliceHD: "pkg:/images/overhang-background-hd.png"
        OverhangLogoHD:  "pkg:/images/logo-hd.png"

        BackgroundColor:       "#404040"
        PosterScreenLine1Text: "#18c314"
        BreadcrumbTextRight:   "#18c314"
    })
    Descend(CreateObject("roPath", ""))
End Sub

Sub Descend(path)
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(m.port)
    screen.SetBreadcrumbText("", path)
    screen.SetListStyle("flat-category")
    screen.Show()
    content = GetContent(path)
    SetContent(screen, content)

    while true
        msg = WaitMessage(m.port)
        if msg.isScreenClosed() or DeviceRemoved(path) return

        if msg.isStorageDeviceAdded() or msg.isStorageDeviceRemoved()
            content = GetContent(path)
            SetContent(screen, content)
        else if msg.isListItemSelected() and msg.GetIndex() < content.Count()
            item = content[msg.GetIndex()]
            if item.RenderFunction = invalid
                Descend(CreateObject("roPath", item.FullPath))
            else
                item.RenderFunction(item, m.port)
            end if
            if DeviceRemoved(path) return
            content = GetContent(path)
            SetContent(screen, content)
        end if
    end while
End Sub

'This function is used to report status on the current device.  If the current
'path is no longer valid because a device has been removed, then return true.
Sub DeviceRemoved(path) As Boolean
    return path.IsValid() and not m.filesystem.Exists(path)
End Sub

'This is a wait wrapper that ignores invalid message objects (from debugging)
Sub WaitMessage(port) As Object
    while true
        msg = wait(0, port)
        if msg <> invalid return msg
    end while
End Sub

'Turns an integer into a comma-separated numeric representation (1,234,567)
Sub PrettyInteger(value) as String
    s = value.tostr()
    r = CreateObject("roRegex", "(\d+)(\d{3})", "")
    while r.IsMatch(s): s = r.Replace(s, "\1,\2"): end while
    return s
End Sub

Sub GetContent(path) As Object
    mimetypes = { 'map known extensions to pseudo-mime-type here
        m4v: "video", mp4: "video", mov: "video", mkv: "video"
        m4a: "audio", mp3: "audio", wma: "audio", mka: "audio"
        jpg: "image", png: "image", gif: "image"
        'Anything else belongs in the "other" category
    }
    renderers = { 'map pseudo-mime-type to display function
        image: RenderImage
        video: RenderVideo
        audio: RenderAudio
        other: RenderOther
    }

    content = []
    if path.IsValid()
        for each c in m.filesystem.GetDirectoryListing(path)
            cpath = CreateObject("roPath", path + "/" + c)
            info = m.filesystem.Stat(cpath)
            desc = invalid
            mimetype = invalid
            if info.type = "directory"
                mimetype = "folder"
            else if info.type = "file"
                mimetype = mimetypes[cpath.Split().extension.mid(1)]
                if mimetype = invalid mimetype = "other"
                desc = "size: " + PrettyInteger(info.size) + " bytes"
            end if
            if mimetype <> invalid content.Push({
                RenderFunction: renderers[mimetype]
                FullPath: cpath
                SDPosterUrl: "pkg:/images/icon-" + mimetype + "-sd.jpg"
                HDPosterUrl: "pkg:/images/icon-" + mimetype + "-hd.jpg"
                ShortDescriptionLine1: c
                ShortDescriptionLine2: desc
            })
        end for
    else
        for each c in m.filesystem.GetVolumeList()
            c = c + "/"
            if c.left(3) = "ext" loc = "ext" else loc = "int"
            info = m.filesystem.GetVolumeInfo(c)
            label = c
            if info.label <> invalid and info.label <> ""
                label = label + " (" + info.label + ")"
            end if
            desc = invalid
            if info.blocks > 0
                usage = int(100.0 * info.usedblocks / info.blocks + 0.5)
                desc = "usage: " + usage.tostr() + "%"
            end if
            content.Push({
                FullPath: c
                SDPosterUrl: "pkg:/images/icon-phy" + loc + "-sd.jpg"
                HDPosterUrl: "pkg:/images/icon-phy" + loc + "-hd.jpg"
                ShortDescriptionLine1: label
                ShortDescriptionLine2: desc
            })
        end for
    end if
    return content
End Sub

Sub SetContent(screen, content)
    screen.SetContentList(content)
    if content.IsEmpty() screen.ShowMessage("this folder is empty")
End Sub

Sub RenderImage(item, port)
    s = CreateObject("roSlideShow")
    s.SetMessagePort(port)
    s.SetContentList([{ Url: "file://" + item.FullPath }])
    s.Show()
    while not WaitMessage(port).isScreenClosed(): end while
End Sub

Sub RenderVideo(item, port)
    s = CreateObject("roVideoScreen")
    s.SetMessagePort(port)
    s.SetContent({
        Title: item.FullPath
        Stream: { url: "file://" + item.FullPath }
    })
    s.Show()
    while not WaitMessage(port).isScreenClosed(): end while
End Sub

Sub RenderAudio(item, port)
    s = CreateObject("roParagraphScreen")
    s.SetBreadcrumbText("", item.FullPath)
    s.SetMessagePort(port)
    s.AddParagraph("Playing " + item.FullPath)
    s.AddButton(0, "done")
    s.Show()
    a = CreateObject("roAudioPlayer")
    a.SetContentList([{ Url: "file://" + item.FullPath }])
    a.Play()
    while not WaitMessage(port).isButtonPressed(): end while
End Sub

Sub RenderOther(item, port)
    s = CreateObject("roParagraphScreen")
    s.SetBreadcrumbText("", item.FullPath)
    s.SetMessagePort(port)
    s.AddButton(0, "done")
    s.Show()
    text = CreateObject("roByteArray")
    text.ReadFile(item.FullPath, 0, 1000)
    s.AddParagraph(text.ToAsciiString())
    while not WaitMessage(port).isButtonPressed(): end while
End Sub
