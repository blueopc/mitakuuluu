import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0

ListItem {
    id: item
    width: parent.width
    contentHeight: model.mediatype == 2 ? Math.max(msgcolumn.height, Theme.itemSizeMedium) : msgcolumn.height
    height: contentItem.height + (menuOpen ? _menuItem.height : 0) + (urlmenuOpen ? _urlmenuItem.height : 0)
    ListView.onRemove: animateRemoval(item)
    menu: componentContextMenu
    contentItem.color: _showPress ? highlightedColor : Theme.rgba(getContactColor(model.author), Theme.highlightBackgroundOpacity)

    property bool showPreview: false
    property Item playerObject: null
    property Item previewObject: null

    property variant urlmenu: componentUrlMenu
    property Item _urlmenuItem: null
    property bool urlmenuOpen: _urlmenuItem != null && _urlmenuItem._open

    onUrlmenuOpenChanged: {
        if (ListView.view && ('__silica_contextmenu_instance' in ListView.view)) {
            ListView.view.__silica_contextmenu_instance = urlmenuOpen ? _urlmenuItem : null
        }
    }

    function remove() {
        remorseAction(qsTr("Remove message"),
                      function() {
                          conversationModel.deleteMessage(model.msgid, deleteMediaFiles)
                      })
    }

    function showUrlMenu(properties) {
        if (urlmenu == null) {
            return null
        }
        if (_urlmenuItem == null) {
            if (urlmenu.createObject !== undefined) {
                _urlmenuItem = urlmenu.createObject(item, properties || {})
                _urlmenuItem.closed.connect(function() { _urlmenuItem.destroy() })
            } else {
                _urlmenuItem = urlmenu
            }
        }
        if (_urlmenuItem) {
            if (urlmenu.createObject === undefined) {
                for (var prop in properties) {
                    if (prop in _urlmenuItem) {
                        _urlmenuItem[prop] = properties[prop];
                    }
                }
            }
            _urlmenuItem.show(item)
        }
        return _urlmenuItem
    }

    Component.onCompleted: {
        if (model.msgtype == 3) {
            if (model.mediatype == 1 || model.mediatype == 3 || model.mediatype == 5) {
                previewObject = previewComponent.createObject(msgcolumn)
            }
            else if (model.mediatype == 2) {
                playerObject = componentAudioPlayer.createObject(playerPlaceholder)
            }
        }
    }


    Component.onDestruction: {
        if (_urlmenuItem != null) {
            _urlmenuItem.hide()
            _urlmenuItem._parentDestroyed()
        }
        if (playerObject != null) {
            playerObject.parent = null
        }
        if (previewObject != null) {
            previewObject.parent = null
        }
    }

    onPressed: {
        if (!menuOpen && !urlmenuOpen)
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
                showUrlMenu({"model" : urlmodel})
            }
        }
        else if (!showPreview) {
            if (model.msgtype == 3 && model.mediatype > 0 && model.mediatype < 4) {
                if (model.localurl.length == 0) {
                    whatsapp.downloadMedia(model.msgid, page.jid)
                    banner.notify(qsTr("Media download started..."))
                }
                else if (model.mediatype == 1) {
                    showPreview = true
                    scrollTimer.position(model.index)
                }
                else {
                    Qt.openUrlExternally(model.localurl)
                }
            }
            else if (model.mediatype == 4) {
                whatsapp.openVCardData(model.medianame, model.message)
            }
            else if (model.mediatype == 5) {
                Qt.openUrlExternally("geo:" + model.medialat + "," + model.medialon)
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
            }
        }
    }

    Connections {
        target: conversationView
        onHideAll: {
            if (imsgid != model.msgid) {
                showPreview = false
            }
        }
    }

    Rectangle {
        width: (model.msgstatus == 5) ? 10 : 5
        color: Theme.rgba(msgStatusColor(model), 0.2)
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        visible: model.author === roster.myJid
    }

    Column {
        id: msgcolumn
        anchors {
            left: parent.left
            leftMargin: Theme.paddingMedium
            top: parent.top
            right: parent.right
            rightMargin: Theme.paddingMedium
        }

        Label {
            id: msginfo
            width: parent.width
            font.pixelSize: fontSize
            text: (showTimestamp ? timestampToTime(model.timestamp) : "") + " <b>&lt;" + roster.getNicknameByJid(model.author) + "&gt;</b> "
            //text: (showTimestamp ? ((isGroup ? "" : "[") + timestampToTime(model.timestamp) + (isGroup ? "" : "]")) : "") + (isGroup ? (" <b>&lt;" + roster.getNicknameByJid(model.author) + "&gt;</b> ") : "")
            elide: Text.ElideRight
            visible: isGroup
            textFormat: Text.RichText
        }

        Label {
            id: msg
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: fontSize
            text: isGroup ? getMessageText(model) : ((showTimestamp ? ("[" + timestampToTime(model.timestamp) + "] ") : "") + getMessageText(model))
            textFormat: Text.RichText
            horizontalAlignment: virtualText.horizontalAlignment
            linkColor: Theme.highlightColor
        }
    }

    Image {
        id: progressIndicator
        anchors {
            top: msgcolumn.top
            left:msgcolumn.left
            bottom: msgcolumn.bottom
        }
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        width: parent.width / 100 * model.mediaprogress
        visible: model.mediaprogress > 0 && model.mediaprogress < 100
        source: "/usr/share/harbour-mitakuuluu/images/progress-pattern-black.png"
    }

    Text {
        id: virtualText
        visible: false
        text: getMessageText(model)
    }

    Component {
        id: previewComponent
        Item {
            id: prevClip
            width: parent.width
            height: showPreview ? prev.height: 100
            anchors.horizontalCenter: parent.horizontalCenter
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
    }

    Item {
        id: playerPlaceholder
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }
        width: Theme.itemSizeMedium
        height: Theme.itemSizeMedium
    }

    Component {
        id: componentAudioPlayer
        Rectangle {
            anchors.fill: parent
            visible: model.localurl.length > 0
            color: Theme.rgba(playButton.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor, 0.5)

            Audio {
                id: player
            }

            IconButton {
                id: playButton
                anchors {
                    centerIn: parent
                }
                icon.source: player.playbackState == Audio.PlayingState ? "image://theme/icon-m-pause"
                                                                        : "image://theme/icon-m-play"
                onClicked: {
                    if (player.playbackState == Audio.PlayingState)
                        player.pause()
                    else
                        player.play()
                }
            }

            Component.onCompleted: {
                player.source = model.localurl
            }
        }
    }

    Component {
        id: componentUrlMenu
        ContextMenu {
            id: urlMenu
            //anchors.bottom: item.bottom
            //width: item.width
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
    }

    Component {
        id: componentContextMenu
        ContextMenu {
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
                visible: model.localurl.indexOf(".whatsapp") > 0
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
                        remove()
                }
            }
        }
    }
}
