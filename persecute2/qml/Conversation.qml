import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "conversation"
    allowedOrientations: Orientation.Portrait

    onStatusChanged: {
        if (page.status === PageStatus.Inactive && pageStack.depth === 1) {
            avatarView.hide()
            if (typingTimer.running)
                typingTimer.stop()
            whatsapp.setActiveJid("")
            whatsapp.endTyping(page.jid)
            if (contactTypingTimer.running)
                contactTypingTimer.stop()
            sendBox.text = ""
        }
        else if (page.status === PageStatus.Active) {
            fontSize = settings.value("fontSize", Theme.fontSizeMedium)
            scrollDown.start()
            if (showKeyboard)
                forceTimer.start()
        }
    }

    property string jid: ""
    property bool isGroup: jid.indexOf("-") != -1
    property variant contacts: null
    property bool available: false
    property bool blocked: false
    property string icon: ""
    property string title: ""
    property string second: ""

    function saveHistory(sjid, sname) {
            conversationModel.saveHistory(sjid, sname)
        }

    function sendMedia(path) {
        console.log("send media: " + path)
        whatsapp.sendMedia([page.jid], path)
        banner.notify("Media uploading started")
    }

    function unbindMedia() {
        selectFile.selected.disconnect(page.sendMedia)
        selectFile.done.disconnect(page.unbindMedia)
    }

    function loadContactModel(model) {
        page.title = (typeof(model.nickname) != "undefined" && model.nickname != "undefined") ? model.nickname : model.jid.split("@")[0]
        page.icon = model.avatar == "undefined" ? "" : model.avatar
        page.available = (typeof(model.available) != "undefined" && model.available != "undefined") ? model.available : false
        page.blocked = (typeof(model.blocked) != "undefined" && model.blocked != "undefined") ? model.blocked : false
        page.jid = model.jid
        whatsapp.setActiveJid(page.jid)
        if (!page.available) {
            page.second = timestampToDateTime(model.timestamp)
            whatsapp.requestLastOnline(page.jid)
        }
        conversationModel.jid = page.jid
    }

    Connections {
        target: roster.contacts
        onNicknameChanged: {
            if (pjid == page.jid)
                page.title = nickname
        }
    }

    function getContactColor(jid) {
        if (isGroup) {
            if (jid == roster.myJid) {
                return "transparent"
            }
            else {
                return roster.getContactColor(jid)
            }
        }
        else {
            if (jid == roster.myJid) {
                return "transparent"
            }
            else {
                return "#20FFFFFF"
            }
        }
    }

    function msgStatusColor(model) {
        if (model.author != roster.myJid) {
            return "transparent"
        }
        else {
            if  (model.msgstatus == 4)
                return "#60ffff00"
            else if  (model.msgstatus == 5)
                return "#6000ff00"
            else
                return "#60ff0000"
        }
    }

    function timestampToDateTime(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd.MM hh:mm:ss")
    }

    function timestampToTime(stamp) {
        var d = new Date(stamp*1000)
        if (showSeconds)
            return Qt.formatDateTime(d, "hh:mm:ss")
        else
            return Qt.formatDateTime(d, "hh:mm")
    }

    function timestampToDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM")
    }

    function compareTimestampDate(stamp1, stamp2) {
        var d1 = new Date(stamp1*1000)
        var d2 = new Date(stamp2*1000)
        return (d1.getDate() == d2.getDate() && d1.getMonth() == d2.getMonth())
    }

    function bytesToSize(bytes) {
        var sizes = [ 'n/a', 'bytes', 'KiB', 'MiB', 'GiB']
        var i = +Math.floor(Math.log(bytes) / Math.log(1024))
        return  (bytes / Math.pow(1024, i)).toFixed( i ? 1 : 0 ) + ' ' + sizes[ isNaN( bytes ) ? 0 : i+1 ]
    }

    function intToTime(value) {
        var sizes = [ 'n/a', 'S', 'M', 'H']
        var i = +Math.floor(Math.log(value) / Math.log(60))
        return  (value / Math.pow(60, i)).toFixed( i ? 1 : 0 ) + ' ' + sizes[ isNaN( value ) ? 0 : i+1 ]
    }

    function getMessageText(model) {
        var fromMe = model.author === roster.myJid
        var direction = " "
        if (fromMe)
            direction = "Outgoing "
        else
            direction = "Incoming "
        if (model.msgtype === 3) { //media
            switch (model.mediatype) {
            case 1: return direction + "picture " + bytesToSize(parseInt(model.mediasize)) + (model.localurl.length > 0 && !fromMe ? " 100%" : (model.mediaprogress > 0 ? (" " + model.mediaprogress + "%") : ""))
            case 2: return direction + "audio " + (model.mediaduration > 0 ? (intToTime(model.mediaduration) + " ") : "") + bytesToSize(parseInt(model.mediasize)) + (model.localurl.length > 0 && !fromMe ? " 100%" : (model.mediaprogress > 0 ? (" " + model.mediaprogress + "%") : ""))
            case 3: return direction + "video " + (model.mediaduration > 0 ? (intToTime(model.mediaduration) + " ") : "") + bytesToSize(parseInt(model.mediasize)) + (model.localurl.length > 0 && !fromMe ? " 100%" : (model.mediaprogress > 0 ? (" " + model.mediaprogress + "%") : ""))
            case 4: return direction + "contact " + model.medianame
            case 5: return direction + "location LAT: " + model.medialon + " LON: " + model.medialat
            default: return direction + "unknown media"
            }
        }
        else if (model.msgtype === 2) {
            return Utilities.linkify(Utilities.emojify(model.message, emojiPath), Theme.highlightColor)
        }
        else {
            return "System message."
        }
    }

    function logMessageDetails(model) {
        console.log("MESSAGE LOG")
        console.log(typeof(model.msgid) + " " + model.msgid)
        console.log(typeof(model.msgtype) + " " + model.msgtype)
        console.log(typeof(model.msgstatus) + " " + model.msgstatus)
        console.log(typeof(model.mediatype) + " " + model.mediatype)
        console.log(typeof(model.mediasize) + " " + model.mediasize)
        console.log(typeof(model.mediathumb) + " " + model.mediathumb)
        console.log(typeof(model.message) + " " + model.message)
    }

    function forwardMsg(jids, msgid) {
        conversationModel.forwardMessage(jids, msgid)
    }

    Connections {
        target: whatsapp
        onPresenceAvailable: {
            if (mjid == page.jid) {
                page.second = ""
                page.available = true
            }
        }
        onPresenceUnavailable: {
            if (mjid == page.jid) {
                page.available = false
                whatsapp.requestLastOnline(page.jid)
            }
        }
        onPresenceLastSeen: {
            if (mjid == page.jid && !page.available) {
                page.second = timestampToDateTime(seconds)
            }
        }
        onPictureUpdated: {
            if (pjid == page.jid) {
                page.icon = ""
                page.icon = path
            }
        }
        onContactTyping: {
            if (cjid == page.jid) {
                contactTypingTimer.start()
            }
        }
        onContactPaused: {
            if (cjid == page.jid) {
                contactTypingTimer.stop()
            }
        }
        onMessageReceived: {
            if (data.jid == page.jid && data.author != roster.myJid && notifyActive) {
                whatsapp.feedbackEffect()
            }
            else if (data.author == roster.myJid) {
                scrollDown.start()
            }
        }
    }

    SilicaFlickable {
        anchors.top: page.top
        anchors.bottom: sendBox.top
        anchors.bottomMargin: Theme.paddingMedium
        width: page.width
        clip: true
        interactive: !conversationView.flicking
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                id: mediaSend
                text: "Send media"
                enabled: roster.connectionStatus == 4
                onClicked: {
                    selectFile.processPath("/home/nemo")
                    selectFile.open()
                    selectFile.selected.connect(page.sendMedia)
                    selectFile.done.connect(page.unbindMedia)
                }
            }

            MenuItem {
                id: removeAll
                text: "Remove all messages"
                onClicked: {
                    var rjid = page.jid
                    remorseAll.execute("Remove all messages",
                                       function() {
                                           conversationModel.removeConversation(rjid)
                                           roster.reloadContact(rjid)
                                       },
                                       5000)
                }
            }

            MenuItem {
                id: contactInfo
                text: "Profile"
                enabled: (roster.connectionStatus == 4) ? true : (page.jid.indexOf("-") == -1)
                onClicked: {
                    profileAction(page.jid)
                }
            }

            MenuItem {
                id: locationSend
                text: "Load old conversation"
                visible: conversationView.count > 19
                onClicked: {
                    conversationModel.loadOldConversation(20)
                }
            }
        }

        PageHeader {
            id: header
            clip: true
            Rectangle {
                smooth: true
                width: parent.width
                height: 2
                anchors.bottom: parent.bottom
                color:  page.blocked ? "#40FF0000" : (roster.connectionStatus == 4 ? (page.available ? "#4000FF00" : "transparent") : "transparent")
            }
            AvatarHolder {
                id: pic
                height: parent.height - (Theme.paddingSmall * 2)
                width: height
                source: page.icon
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        avatarView.show(page.icon)
                    }
                }
            }
            Column {
                id: hColumn
                anchors.left: parent.left
                anchors.leftMargin: pic.width
                anchors.right: pic.left
                spacing: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    id: nameText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    font.family: Theme.fontFamily
                    text: Utilities.emojify(page.title, emojiPath)
                }
                Label {
                    id: lastSeenText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.family: Theme.fontFamily
                    text: "Last seen: " + page.second
                    visible: !available && page.jid.indexOf("-") == -1 && text.length > 0
                }
            }
            ProgressBar {
                id: typingItem
                anchors.top: hColumn.bottom
                anchors.horizontalCenter: hColumn.horizontalCenter
                width: nameText.width
                height: 5
                indeterminate: true
                visible: typingTimer.running
                minimumValue: 0
                maximumValue: 1
                value: 1
            }
        }

        SilicaListView {
            id: conversationView
            model: conversationModel
            anchors.top: header.bottom
            width: parent.width
            anchors.bottom: parent.bottom
            clip: true
            cacheBuffer: page.height * 2
            pressDelay: 0
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: listDelegate
            property bool shouldGotoEnd: false
            property bool shouldLoadLast: false
            property int contentYPos: 0
            property int bottomHeight: 0
            signal hideAll(string imsgid)
            signal remove(string rmsgid)
            section.property: "msgdate"
            section.delegate: sectionDelegate
            onMovementEnded: {
                if (shouldLoadLast && conversationView.count > 19)
                    conversationModel.loadOldConversation(20)
                shouldLoadLast = false
                bottomHeight = contentHeight - contentY - height
            }
            onContentYChanged: {
                contentYPos = conversationView.visibleArea.yPosition * Math.max(conversationView.height, conversationView.contentHeight)
                if (contentYPos < -80)
                    shouldLoadLast = true
                if (atYEnd && newMessageItem.visible) {
                    newMessageItem.opacity = 0.0
                }
            }
            onHeightChanged: {
                if (contentHeight > height) {
                    var bheight = contentHeight - contentY - height
                    contentY += bheight - bottomHeight
                    bottomHeight = contentHeight - contentY - height
                }
            }
            FastScroll {
                id: fastScroll
                listView: conversationView
            }
            MouseArea {
                id: newMessageItem
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: visible ? (message.paintedHeight + (Theme.paddingLarge * 2)) : 0
                visible: opacity > 0
                opacity: 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                        properties: "opacity,height"
                    }
                }

                Rectangle {
                    id: bg
                    anchors.fill: parent
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    id: message
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingRight
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    text: "New message"
                }

                onClicked: {
                    conversationView.positionViewAtIndex(conversationView.count - 1, conversationView.Contain)
                    opacity = 0.0
                }
            }
        }

        /*VerticalScrollDecorator {
            flickable: conversationView
        }*/
    }

    Rectangle {
        width: page.width
        anchors.bottom: sendBox.top
        height: 2
        color: Theme.secondaryColor
    }

    EmojiTextArea {
        id: sendBox
        anchors.bottom: page.bottom
        anchors.bottomMargin: - Theme.paddingLarge
        anchors.left: page.left
        anchors.leftMargin: - Theme.paddingMedium
        anchors.right: page.right
        anchors.rightMargin: - Theme.paddingMedium
        placeholderText: "Tap here to enter message"
        property int lastYPos: 0
        property bool forceFocus: false
        showEmoji: false
        showAction: !sendByEnter
        actionButton.enabled: roster.connectionStatus == 4 && text.trim().length > 0
        /*onEmojiClicked: {
            if (emojiChecked) {
                Qt.inputMethod.hide()
            }
            else {
                Qt.inputMethod.show()
            }
            //appWindow.customInputPanel.visible = emojiChecked
        }*/
        onAction: {
            send()
        }
        EnterKey.enabled: sendByEnter ? (roster.connectionStatus == 4 && text.trim().length > 0) : true
        EnterKey.highlighted: text.trim().length > 0
        EnterKey.iconSource: sendByEnter ? "image://theme/icon-m-message" : "image://theme/icon-m-enter"
        EnterKey.onClicked: {
            if (sendByEnter) {
                send()
            }
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                lastYPos = conversationView.contentY
            }
            if (activeFocus && conversationView.atYEnd)
                scrollDown.start()
        }
        onFocusChanged: {
            if (!focus) {
                if (forceFocus) {
                    Qt.inputMethod.show()
                    forceActiveFocus()
                }
                /*else if (appWindow.customInputPanel.visible) {
                    appWindow.customInputPanel.visible = false
                }*/
                //emojiChecked = false
            }
            forceFocus = false
        }
        onTextChanged: {
            if (!typingTimer.running) {
                whatsapp.startTyping(page.jid)
                typingTimer.start()
            }
            else
                typingTimer.restart()
        }
        function send() {
            deselect()
            whatsapp.sendText(page.jid, sendBox.text.trim())
            sendBox.text = ""
            forceTimer.start()
        }
    }

    Rectangle {
        id: avatarView
        anchors.fill: parent
        color: "#A0000000"
        opacity: 0.0
        Behavior on opacity {
            FadeAnimation {}
        }
        function show(path) {
            avaView.source = path
            avatarView.opacity = 1.0
            page.backNavigation = false
        }
        function hide() {
            avaView.source = ""
            avatarView.opacity = 0.0
            page.backNavigation = true
        }
        Image {
            id: avaView
            anchors.centerIn: parent
            asynchronous: true
            cache: false
        }
        MouseArea {
            enabled: avatarView.opacity > 0
            anchors.fill: parent
            onClicked: avatarView.hide()
        }
    }

    RemorsePopup {
        id: remorseAll
    }

    ConversationModel {
        id: conversationModel
        onLastMessageChanged: {
            if (mjid == page.jid && (conversationView.shouldGotoEnd || force)) {
                if (conversationView.contentHeight > conversationView.height)
                    scrollDown.start()
                conversationView.shouldGotoEnd = false
            }
            fastScroll.init()
        }
        onLastMessageToBeChanged: {
            if (mjid == page.jid && conversationView.atYEnd)
                conversationView.shouldGotoEnd = true
            else
               newMessageItem.opacity = 1.0
        }
    }

    Component {
        id: sectionDelegate
        Item {
            width: parent.width //ListView.view.width
            height: sectionLabel.paintedHeight
            Label {
                id: sectionLabel
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                horizontalAlignment: Text.AlignRight
                font.pixelSize: fontSize
                color: Theme.highlightColor
                text: section
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("header hide all")
                    conversationView.hideAll("")
                }
            }
        }
    }

    Component {
        id: listDelegate
        Item {
            id: item
            width: parent.width
            height: msg.height + (isGroup ? msginfo.height : 0) + (prevClip.visible ? (prev.status == Image.Ready ? prevClip.height : 0) : 0) + (inMenu.visible ? inMenu.height : 0) + (urlMenu.visible ? urlMenu.height : 0)
            //color:
            opacity: mArea.pressed ? 0.5 : 1.0
            property bool showPreview: false

            Connections {
                target: conversationView
                onHideAll: {
                    if (imsgid != model.msgid)
                        showPreview = false
                }
            }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                anchors.bottom: parent.bottom
                color: getContactColor(model.author)
            }

            Rectangle {
                width: (model.msgstatus == 5) ? 10 : 5
                color: msgStatusColor(model)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
            }

            Label {
                id: msginfo
                font.pixelSize: fontSize
                text: (showTimestamp ? timestampToTime(model.timestamp) : "") + " <b>&lt;" + roster.getNicknameByJid(model.author) + "&gt;</b> "
                //text: (showTimestamp ? ((isGroup ? "" : "[") + timestampToTime(model.timestamp) + (isGroup ? "" : "]")) : "") + (isGroup ? (" <b>&lt;" + roster.getNicknameByJid(model.author) + "&gt;</b> ") : "")
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingMedium
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                elide: Text.ElideRight
                visible: isGroup
                textFormat: Text.RichText
            }

            Label {
                id: msg
                wrapMode: Text.Wrap
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingMedium
                anchors.top: isGroup ? msginfo.bottom : parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                font.pixelSize: fontSize
                text: isGroup ? getMessageText(model) : ((showTimestamp ? ("[" + timestampToTime(model.timestamp) + "] ") : "") + getMessageText(model))
                textFormat: Text.RichText
                horizontalAlignment: virtualText.horizontalAlignment
            }

            Text {
                id: virtualText
                visible: false
                text: getMessageText(model)
            }

            Item {
                id: prevClip
                anchors.top: msg.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: showPreview ? prev.height: 100
                visible: model.msgtype == 3 && (model.mediatype == 1 || model.mediatype == 3 || model.mediatype == 5)
                clip: true
                Image {
                    id: prev
                    fillMode: Image.PreserveAspectFit
                    source: visible ? (model.localurl.length > 0 ? model.localurl : (model.mediathumb.length > 0 ? ("data:image/png;base64," + model.mediathumb) : "")) : ""
                    width: parent.width
                    sourceSize.width: parent.width
                    asynchronous: true
                    cache: true
                    clip: true
                    smooth: true
                }
            }

            Image {
                id: progressIndicator
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: menuIndicator.top
                anchors.bottomMargin: - menuIndicator.height
                fillMode: Image.Tile
                horizontalAlignment: Image.AlignLeft
                verticalAlignment: Image.AlignTop
                width: parent.width / 100 * model.mediaprogress
                visible: model.mediaprogress > 0 && model.mediaprogress < 100
                source: "/usr/share/harbour-mitakuuluu/images/progress-pattern-black.png"
            }

            MouseArea {
                id: mArea
                anchors.fill: parent
                onPressed: {
                    if (!inMenu.active)
                        conversationView.hideAll(model.msgid)
                }
                onClicked: {
                    if (model.msgtype == 2) {
                        //console.log(msg.text)
                        var links = msg.text.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/gi);
                        if (links && links.length > 0) {
                            //console.log(JSON.stringify(links))
                            var urlmodel = []
                            links.forEach(function(link) {
                                var groups = link.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/i);
                                //console.log(JSON.stringify(groups))
                                var urlink = [groups[2], groups[1]]
                                urlmodel[urlmodel.length] = urlink
                            });
                            urlMenu.model = urlmodel
                            urlMenu.show(item)
                        }
                    }
                    else if (!showPreview) {
                        if (model.msgtype == 3 && model.mediatype > 0 && model.mediatype < 4 && model.localurl.length == 0) {
                            whatsapp.downloadMedia(model.msgid, page.jid)
                            banner.notify("Media download started...")
                        }
                        else {
                            showPreview = true
                            scrollTimer.position(model.index)
                        }
                    }
                    else {
                        if (model.msgtype == 3) {
                            if (model.mediatype > 0 && model.mediatype < 4) {
                                if (model.localurl.length > 0) {
                                    Qt.openUrlExternally(model.localurl)
                                }
                                else {
                                    whatsapp.downloadMedia(model.msgid, page.jid)
                                }
                            }
                            else if (model.mediatype == 4) {
                                whatsapp.openVCardData(model.medianame, model.message)
                            }
                            else if (model.mediatype == 5) {
                                Qt.openUrlExternally("geo:" + model.medialon + "," + model.medialat + "?action=showOnMap")
                            }
                        }
                    }
                }
                onPressAndHold: {
                    console.log(model.message)
                    inMenu.show(item)
                }
            }

            Connections {
                target: conversationView
                onRemove: {
                    var dmsgid = rmsgid
                    if (dmsgid === model.msgid) {
                        removeItem.execute(item,
                                           "Remove message",
                                           function() {
                                               conversationModel.deleteMessage(dmsgid)
                                           },
                                           5000)
                    }
                }
            }

            RemorseItem {
                id: removeItem
                anchors.fill: parent
            }

            MenuIndicator {
                id: menuIndicator
                anchors.bottom: item.bottom
                anchors.bottomMargin: inMenu.height - (height / 2)
                width: item.width
                visible: inMenu.active || urlMenu.active
            }

            ContextMenu {
                id: urlMenu
                anchors.bottom: item.bottom
                width: item.width
                property alias model: urlMenuRepeater.model
                Repeater {
                    id: urlMenuRepeater
                    property alias childs: urlMenuRepeater.model
                    width: parent.width
                    delegate: MenuItem {
                        parent: urlMenuRepeater
                        text: modelData[0]
                        onClicked: {
                            Qt.openUrlExternally(modelData[1])
                        }
                    }
                }
            }

            ContextMenu {
                id: inMenu
                anchors.bottom: item.bottom
                width: item.width

                MenuItem {
                    text: "Copy"
                    enabled: conversationModel.getModelByMsgId(model.msgid).mediatype != 4
                    onClicked: {
                        conversationModel.copyToClipboard(model.msgid)
                        banner.notify("Message copied to clipboard")
                    }
                }

                MenuItem {
                    text: "Forward"
                    enabled: roster.connectionStatus == 4
                    onClicked: {
                        forwardMessage.loadMessage(conversationModel.getModelByMsgId(model.msgid), page.jid)
                        forwardMessage.open()
                    }
                }

                MenuItem {
                    id: removeMsg
                    text: (model.mediaprogress > 0 && model.mediaprogress < 100) ? "Cancel download" : "Delete"
                    onClicked: {
                        if (model.mediaprogress > 0 && model.mediaprogress < 100)
                            whatsapp.cancelDownload(dmsgid, page.jid)
                        else
                            conversationView.remove(model.msgid)
                    }
                }
            }
        }
    }

    Timer {
        id: scrollTimer
        interval: 300
        triggeredOnStart: false
        repeat: false
        onTriggered: conversationView.positionViewAtIndex(saveindex, ListView.Contain)
        function position(needindex) {
            saveindex = needindex
            start()
        }
        property int saveindex: -1
    }

    Timer {
        id: contactTypingTimer
        interval: 10000
        triggeredOnStart: false
        repeat: false
        //onTriggered: typingIcon.source = ""
    }

    Timer {
        id: forceTimer
        interval: 300
        triggeredOnStart: false
        repeat: false
        onTriggered: sendBox.forceActiveFocus()
    }

    Timer {
        id: typingTimer
        interval: 5000
        triggeredOnStart: false
        repeat: false
        onTriggered: whatsapp.endTyping(page.jid)
    }

    Timer {
        id: scrollDown
        interval: 500
        triggeredOnStart: false
        repeat: false
        onTriggered: conversationView.positionViewAtIndex(conversationView.count - 1, conversationView.Contain)
    }
}
