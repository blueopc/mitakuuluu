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
        banner.notify(qsTr("Media uploading started"))
    }

    function unbindMediaImage() {
        selectPicture.selected.disconnect(page.sendMedia)
        selectPicture.done.disconnect(page.unbindMediaImage)
    }

    function unbindMediaFile() {
        selectFile.selected.disconnect(page.sendMedia)
        selectFile.done.disconnect(page.unbindMediaFile)
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

    function intToTime(value) {
        var sizes = [ qsTr('n/a'), qsTr('S'), qsTr('M'), qsTr('H')]
        var i = +Math.floor(Math.log(value) / Math.log(60))
        return  (value / Math.pow(60, i)).toFixed( i ? 1 : 0 ) + ' ' + sizes[ isNaN( value ) ? 0 : i+1 ]
    }

    function getMessageText(model) {
        var fromMe = model.author === roster.myJid
        var direction = " "
        if (fromMe)
            direction = qsTr("Outgoing ")
        else
            direction = qsTr("Incoming ")
        if (model.msgtype === 3) { //media
            switch (model.mediatype) {
            case 1: return direction + qsTr("picture ") + bytesToSize(parseInt(model.mediasize)) + (model.localurl.length > 0 && !fromMe ? " 100%" : (model.mediaprogress > 0 ? (" " + model.mediaprogress + "%") : ""))
            case 2: return direction + qsTr("audio ") + (model.mediaduration > 0 ? (intToTime(model.mediaduration) + " ") : "") + bytesToSize(parseInt(model.mediasize)) + (model.localurl.length > 0 && !fromMe ? " 100%" : (model.mediaprogress > 0 ? (" " + model.mediaprogress + "%") : ""))
            case 3: return direction + qsTr("video ") + (model.mediaduration > 0 ? (intToTime(model.mediaduration) + " ") : "") + bytesToSize(parseInt(model.mediasize)) + (model.localurl.length > 0 && !fromMe ? " 100%" : (model.mediaprogress > 0 ? (" " + model.mediaprogress + "%") : ""))
            case 4: return direction + qsTr("contact ") + model.medianame
            case 5: return direction + qsTr("location ") + qsTr("LAT: %1").arg(model.medialon) + qsTr(" LON: %1").arg(model.medialat)
            default: return direction + "unknown media"
            }
        }
        else if (model.msgtype === 2) {
            return Utilities.linkify(Utilities.emojify(model.message, emojiPath), Theme.highlightColor)
        }
        else {
            return qsTr("System message.")
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
                text: qsTr("Send media")
                enabled: roster.connectionStatus == 4
                onClicked: {
                    pageStack.push(selectMedia)
                }
            }

            MenuItem {
                id: removeAll
                text: qsTr("Remove all messages")
                onClicked: {
                    var rjid = page.jid
                    remorseAll.execute(qsTr("Remove all messages"),
                                       function() {
                                           conversationModel.removeConversation(rjid)
                                           roster.reloadContact(rjid)
                                       },
                                       5000)
                }
            }

            MenuItem {
                id: contactInfo
                text: qsTr("Profile")
                enabled: (roster.connectionStatus == 4) ? true : (page.jid.indexOf("-") == -1)
                onClicked: {
                    profileAction(page.jid)
                }
            }

            MenuItem {
                id: locationSend
                text: qsTr("Load old conversation")
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
                height: 20
                anchors.bottom: parent.bottom
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: 1.0
                        color: page.blocked ? "#40FF0000" : (roster.connectionStatus == 4 ? (page.available ? "#4000FF00" : "transparent") : "transparent")
                    }
                }
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
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    truncationMode: TruncationMode.Fade
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
            delegate: Component {
                id: delegateComponent
                Loader {
                    width: parent.width
                    asynchronous: asynchronousDelegate
                    source: conversationTheme
                }
            }
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
                    text: qsTr("New message")
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
        placeholderText: qsTr("Tap here to enter message")
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

    Page {
        id: selectMedia

        SilicaFlickable {
            id: mFlick
            anchors.fill: parent
            property int itemWidth: width / 2
            property int itemHeight: (height / 2) - (mHeader.height / 2)

            PageHeader {
                id: mHeader
                title: qsTr("Select media type")
            }

            SquareButton {
                anchors.left: parent.left
                anchors.top: mHeader.bottom
                width: mFlick.itemWidth
                height: mFlick.itemHeight
                icon.source: "image://theme/icon-m-image"
                onClicked: {
                    selectPicture.selected.connect(page.sendMedia)
                    selectPicture.setProcessImages()
                    selectPicture.open(true)
                    selectFile.done.connect(page.unbindMediaImage)
                }
            }

            SquareButton {
                anchors.right: parent.right
                anchors.top: mHeader.bottom
                width: mFlick.itemWidth
                height: mFlick.itemHeight
                icon.source: "image://theme/icon-m-video"
                onClicked: {
                    selectFile.processPath("/home/nemo", qsTr("Select video"))
                    selectFile.setFilter(["*.mp4", "*.avi", "*.mov"])
                    pageStack.replace(selectFile)
                    selectFile.selected.connect(page.sendMedia)
                    selectFile.done.connect(page.unbindMediaFile)
                }
            }

            SquareButton {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: mFlick.itemWidth
                height: mFlick.itemHeight
                icon.source: "image://theme/icon-m-music"
                onClicked: {
                    selectFile.processPath("/home/nemo", qsTr("Select audio"))
                    selectFile.setFilter(["*.mp3", "*.aac", "*.flac", "*.wav"])
                    pageStack.replace(selectFile)
                    selectFile.selected.connect(page.sendMedia)
                    selectFile.done.connect(page.unbindMediaFile)
                }
            }
        }
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
