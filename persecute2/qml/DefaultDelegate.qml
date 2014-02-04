import QtQuick 2.0
import Sailfish.Silica 1.0
import "file:///usr/share/harbour-mitakuuluu/qml"

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
        textFormat: Text.StyledText
        horizontalAlignment: virtualText.horizontalAlignment
        linkColor: Theme.highlightColor
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
        anchors.fill: parent
        onPressed: {
            if (!inMenu.active)
                conversationView.hideAll(model.msgid)
        }
        onClicked: {
            if (model.msgtype == 2) {
                var links = msg.text.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/gi);
                if (links && links.length > 0) {
                    var urlmodel = []
                    links.forEach(function(link) {
                        var groups = link.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/i);
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
