import QtQuick 2.0
import Sailfish.Silica 1.0
import "file:///usr/share/harbour-mitakuuluu/qml"

Item {
    id: item
    width: parent.width
    height: (msg.height + (isGroup ? 0 : Theme.paddingMedium)) + (isGroup ? msginfo.height : 0) + ((msgStatusViewFirstTick.height * 2)+ (isGroup ? Theme.paddingMedium : 0)) + (prevClip.visible ? (prev.status == Image.Ready ? prevClip.height : 0) : 0) + (inMenu.visible ? inMenu.height : 0) + (urlMenu.visible ? urlMenu.height : 0)
    opacity: mArea.pressed ? 0.5 : 1.0
    property bool showPreview: false
    property int msgStatus: model.msgstatus
    onMsgStatusChanged: setTickView()

    function setTickView() {
        switch(msgStatus) {
        case 4:
            msgStatusViewFirstTick.color = "#6000ff00";
            msgStatusViewSecondTick.visible = false;
            break;
        case 5:
            msgStatusViewFirstTick.color = "#6000ff00";
            msgStatusViewSecondTick.color = "#6000ff00";
            msgStatusViewSecondTick.visible = true;
            break;
        default:
            msgStatusViewFirstTick.color = "#60ff0000";
            msgStatusViewSecondTick.visible = false;
        }
    }

    Component.onCompleted: {
        if (model.author === roster.myJid) {
            bubble.anchors.left = item.left;
            bubble.anchors.leftMargin = Theme.paddingMedium;
            msginfo.anchors.left = item.left;
            msginfo.anchors.leftMargin = Theme.paddingLarge;
            msg.anchors.left = item.left;
            msg.anchors.leftMargin = Theme.paddingLarge;
            timeStatusRow.anchors.left = item.left;
            timeStatusRow.anchors.leftMargin = Theme.paddingLarge;
            msginfo.horizontalAlignment = Text.AlignLeft;
            msg.horizontalAlignment = Text.AlignLeft;
            bubble.color = Theme.rgba("#ADD8E6", 0.4);
            setTickView();
        }
        else {
            msgStatusViewFirstTick.visible = false;
            msgStatusViewSecondTick.visible = false;
            msgStatusViewFirstTick.width = 0;
            msgStatusViewSecondTick.width = 0;
            if (model.msgtype === 100) {
                bubble.anchors.horizontalCenter = item.horizontalCenter
                msg.anchors.horizontalCenter = item.horizontalCenter
                msg.horizontalAlignment = Text.AlignHCenter
                msginfo.anchors.horizontalCenter = item.horizontalCenter;
                msginfo.anchors.rightMargin = Theme.paddingLarge;
                msginfo.horizontalAlignment = Text.AlignHCenter;
                timeStatusRow.anchors.horizontalCenter = item.horizontalCenter;
            }
            else {
                bubble.anchors.right = item.right;
                bubble.anchors.rightMargin = Theme.paddingMedium;
                msginfo.anchors.right = item.right;
                msginfo.anchors.rightMargin = Theme.paddingLarge;
                msginfo.horizontalAlignment = Text.AlignRight;
                msg.anchors.right = item.right;
                msg.anchors.rightMargin = Theme.paddingLarge;
                msg.horizontalAlignment = Text.AlignRight;
                timeStatusRow.anchors.right = item.right;
                timeStatusRow.anchors.rightMargin = Theme.paddingLarge;
            }
            bubble.color = getContactColor(model.author);
        }
    }

    function getWidthBubble() {
        var maxBubbleWidth = item.width - ((Theme.paddingMedium * 2) + (Theme.paddingSmall * 2));
        var widthMessage = ((msg.paintedWidth > msginfo.width || !isGroup) ? ((msg.paintedWidth > timeStatusRow.width) ? msg.paintedWidth : timeStatusRow.width) : ((msginfo.width > timeStatusRow.width && isGroup) ?  msginfo.width : timeStatusRow.width)) + (Theme.paddingMedium * 2);
        if (widthMessage > maxBubbleWidth) {
            return maxBubbleWidth;
        }
        else {
            return widthMessage;
        }
    }

    Connections {
        target: conversationView
        onHideAll: {
            if (imsgid != model.msgid)
                showPreview = false
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            conversationView.hideAll(model.msgid)
        }
    }

    Rectangle {
        id: bubble
        anchors {
            top: parent.top; topMargin: Theme.paddingSmall
            bottom: parent.bottom; bottomMargin: Theme.paddingSmall + (inMenu.height || 0) + (urlMenu.height || 0)
        }
        width: Math.max(getWidthBubble(), Theme.itemSizeLarge * 2)
        radius: 8
    }

    Label {
        id: msginfo
        font.pixelSize: fontSize
        color: Theme.highlightColor
        text: "<b>" + roster.getNicknameByJid(model.author) + "</b>"
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingMedium
        elide: Text.ElideRight
        visible: isGroup
        textFormat: Text.RichText
    }

    Label {
        id: msg
        wrapMode: Text.Wrap
        anchors.top: isGroup ? msginfo.bottom : parent.top
        anchors.topMargin: isGroup ? 0 : Theme.paddingMedium
        font.pixelSize: fontSize
        color: Theme.primaryColor
        text: getMessageText(model)
        textFormat: Text.StyledText
        linkColor: Theme.highlightColor
        width: parent.width - (Theme.paddingLarge * 2)
    }

    Row {
        id: timeStatusRow
        anchors.top: msg.bottom
        spacing: 0

        Label {
            id: msgTimeStamp
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
            text: timestampToTime(model.timestamp)
            anchors.verticalCenter: parent.verticalCenter
            visible: showTimestamp
            width: paintedWidth + (model.author !== roster.myJid ? 0 : Theme.paddingMedium)
        }

        GlassItem {
            id: msgStatusViewFirstTick
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            falloffRadius: 0.3
            radius: 0.4
        }

        GlassItem {
            id: msgStatusViewSecondTick
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            falloffRadius: 0.3
            radius: 0.4
        }
    }

    Item {
        id: prevClip
        anchors.top: showTimestamp ? timeStatusRow.bottom : msg.bottom
        anchors.left: bubble.left
        anchors.right: bubble.right
        anchors.leftMargin: Theme.paddingMedium
        anchors.rightMargin: Theme.paddingMedium
        height: showPreview ? prev.height: 100
        visible: model.msgtype == 3 && (model.mediatype == 1 || model.mediatype == 3 || model.mediatype == 5)
        clip: true
        Image {
            id: prev
            fillMode: Image.PreserveAspectFit
            source: visible ? getMediaPreview(model) : ""
            width: parent.width
            sourceSize.width: parent.width
            asynchronous: true
            cache: true
            clip: true
            smooth: true
            rotation: (model.localurl.length > 0) ? whatsapp.getExifRotation(model.localurl) : 0
        }
    }

    Image {
        id: progressIndicator
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingSmall
        anchors.bottom: parent.bottom
        anchors.bottomMargin: inMenu.height || urlMenu.height || 0
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        width: parent.width / 100 * model.mediaprogress
        visible: model.mediaprogress > 0 && model.mediaprogress < 100
        source: "/usr/share/harbour-mitakuuluu/images/progress-pattern-black.png"
    }

    MouseArea {
        id: mArea
        anchors.fill: bubble
        onPressed: {
            if (!inMenu.active && !urlMenu.active)
                conversationView.hideAll(model.msgid)
        }
        onClicked: {
            if (model.msgtype == 100)
                return
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
                    banner.notify(qsTr("Media download started..."))
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
            console.log(model.mediamime)
            inMenu.show(item)
        }
    }

    Connections {
        target: conversationView
        onRemove: {
            var dmsgid = rmsgid
            if (dmsgid === model.msgid) {
                removeItem.execute(item,
                                   qsTr("Remove message"),
                                   function() {
                                       conversationModel.deleteMessage(dmsgid, deleteMediaFiles)
                                   },
                                   5000)
            }
        }
    }

    RemorseItem {
        id: removeItem
        anchors.fill: parent
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
                elide: Text.ElideRight
                truncationMode: TruncationMode.Fade
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
            text: qsTr("Copy")
            enabled: conversationModel.getModelByMsgId(model.msgid).mediatype != 4
            onClicked: {
                conversationModel.copyToClipboard(model.msgid)
                banner.notify(qsTr("Message copied to clipboard"))
            }
        }

        MenuItem {
            text: qsTr("Forward")
            enabled: roster.connectionStatus == 4
            onClicked: {
                forwardMessage.loadMessage(conversationModel.getModelByMsgId(model.msgid), page.jid)
                forwardMessage.open()
            }
        }

        MenuItem {
            visible: model.localurl.indexOf(".whatsapp") !== -1
            text: qsTr("Save to Gallery")
            onClicked: {
                var fname = whatsapp.saveImage(model.localurl)
                banner.notify(qsTr("File saved as %1").arg(fname))
            }
        }

        MenuItem {
            id: removeMsg
            text: (model.mediaprogress > 0 && model.mediaprogress < 100) ? qsTr("Cancel download") : qsTr("Delete")
            onClicked: {
                if (model.mediaprogress > 0 && model.mediaprogress < 100)
                    whatsapp.cancelDownload(dmsgid, page.jid)
                else
                    conversationView.remove(model.msgid)
            }
        }
    }
}
