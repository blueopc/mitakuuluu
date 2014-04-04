import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import QtMultimedia 5.0
import "Utilities.js" as Utilities

MouseArea {
    id: item

    property bool down: pressed && containsMouse

    width: parent.width
    height: content.height + Theme.paddingLarge + (menuOpen ? (_menuItem.height + Theme.paddingMedium) : 0) + (urlmenuOpen ? (_urlmenuItem.height + Theme.paddingMedium) : 0)
    ListView.onRemove: animateRemoval(item)
    property bool __silica_item_removed: false
    Binding on opacity {
        when: __silica_item_removed
        value: 0.0
    }

    property variant menu: componentContextMenu
    property Item _menuItem: null
    property bool menuOpen: _menuItem != null && _menuItem._open

    property variant urlmenu: componentUrlMenu
    property Item _urlmenuItem: null
    property bool urlmenuOpen: _urlmenuItem != null && _urlmenuItem._open

    property string myJid: roster.myJid
    property variant messageColor: down ? highlightColor : contactColor
    property variant contactColor: Theme.rgba(getContactColor(model.author), Theme.highlightBackgroundOpacity)
    property variant highlightColor: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

    property int maxWidth: parent.width - Theme.itemSizeLarge
    onMaxWidthChanged: changeMessageWidth()

    DragFilter.screenMargin: Theme.paddingLarge
    onPressed: item.DragFilter.begin(mouse.x, mouse.y)
    onCanceled: item.DragFilter.end()
    onPreventStealingChanged: if (preventStealing) item.DragFilter.end()

    Component.onCompleted: {
        if (model.msgtype == 3) {
            if (model.mediatype == 1) {
                imageLoader.active = true
                if (model.medianame.indexOf("geometry:") == 0) {
                    var geometry = model.medianame.split(":")
                    var width = geometry[1]
                    var height = geometry[2]
                    imageLoader.width = Math.min(parseInt(width), maxWidth)
                    imageLoader.height = parseInt(height) / (parseInt(width) / imageLoader.width)
                }
            }
            else if (model.mediatype == 2) {
                playerLoader.active = true
            }
            else if (model.mediatype == 3) {
                videoLoader.active = true
            }
            else if (model.mediatype == 4) {
                contactLoader.active = true
            }
            else if (model.mediatype == 5) {
                locationLoader.active = true
            }
        }
        else if (model.msgtype == 2) {
            textLoader.active = true
        }
    }

    Component.onDestruction: {
        if (_menuItem != null) {
            _menuItem.hide()
            _menuItem._parentDestroyed()
        }
        if (_urlmenuItem != null) {
            _urlmenuItem.hide()
            _urlmenuItem._parentDestroyed()
        }

        // This item must not be removed if reused in an ItemPool
        __silica_item_removed = false
    }

    onClicked: {
        if (model.msgtype == 2) {
            var links = message.text.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/gi);
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
        else {
            openMedia()
        }
    }
    onPressAndHold: {
        showMenu()
    }

    onMenuOpenChanged: {
        if (ListView.view && ('__silica_contextmenu_instance' in ListView.view)) {
            ListView.view.__silica_contextmenu_instance = menuOpen ? _menuItem : null
        }
    }

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

    function remorseAction(text, action, timeout) {
        // null parent because a reference is held by RemorseItem until
        // it either triggers or is cancelled.
        var remorse = remorseComponent.createObject(null)
        remorse.execute(contentItem, text, action, timeout)
    }

    function animateRemoval(delegate) {
        if (delegate === undefined) {
            delegate = item
        }
        removeComponent.createObject(delegate, { "target": delegate })
    }

    function showMenu(properties) {
        if (menu == null) {
            return null
        }
        if (_menuItem == null) {
            if (menu.createObject !== undefined) {
                _menuItem = menu.createObject(item, properties || {})
                _menuItem.closed.connect(function() { _menuItem.destroy() })
            } else {
                _menuItem = menu
            }
        }
        if (_menuItem) {
            if (menu.createObject === undefined) {
                for (var prop in properties) {
                    if (prop in _menuItem) {
                        _menuItem[prop] = properties[prop];
                    }
                }
            }
            _menuItem.show(item)
        }
        return _menuItem
    }

    function hideMenu() {
        if (_menuItem != null) {
            _menuItem.hide()
        }
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

    function hideUrlMenu() {
        if (_urlmenuItem != null) {
            _urlmenuItem.hide()
        }
    }

    function downloadMedia() {
        banner.notify(qsTr("Media download started..."))
        whatsapp.downloadMedia(model.msgid, page.jid)
    }

    function cancelMedia() {
        banner.notify(qsTr("Media download canceled."))
        whatsapp.cancelDownload(model.msgid, page.jid)
    }

    function openMedia() {
        if (model.msgtype == 3) {
            if (model.mediatype == 1 || model.mediatype == 3) {
                if (model.localurl.length > 0)
                    Qt.openUrlExternally(model.localurl)
            }
            else if (model.mediatype == 4) {
                whatsapp.openVCardData(model.medianame, model.message)
            }
            else if (model.mediatype == 5) {
                Qt.openUrlExternally("geo:" + model.medialat + "," + model.medialon)
            }
        }
    }

    function changeMessageWidth() {
        message.width = undefined
        if (message.paintedWidth > maxWidth) {
            message.width = maxWidth
        }
    }

    function locationPreview(w, h, lat, lon, z) {
        return "http://m.nok.it/?ctr="
                + lat
                + ","
                + lon
                + "&w=" + w
                + "&h=" + h
                + "&poix0="
                + lat
                + ","
                + lon
                + ";red;white;20;.;"
                + "&z=" + z
                + "&nord&f=0&poithm=1&poilbl=0"
    }

    Item {
        id: arrowBg
        clip: true
        y: mainBg.y + Theme.paddingMedium
        property int size: Math.sqrt(rectBg.width*rectBg.width + rectBg.height*rectBg.height)
        height: size
        width: size / 2
        Component.onCompleted: {
            if (model.author === myJid) {
                anchors.left = mainBg.right
            }
            else {
                anchors.right = mainBg.left
            }
        }

        Rectangle {
            id: rectBg
            color: messageColor
            width: Math.sqrt(Theme.paddingLarge*Theme.paddingLarge*2) / 2
            height: width
            rotation: 45
            y: (arrowBg.size - width) / 2
            Component.onCompleted: {
                if (model.author === myJid) {
                    x = 0 - (arrowBg.size - width) - 1
                }
                else {
                    x = (arrowBg.size - width) / 2
                }
            }
        }
    }

    Rectangle {
        id: mainBg
        anchors {
            fill: content
            margins: - Theme.paddingSmall
        }
        color: messageColor
    }

    Column {
        id: content
        anchors {
            top: parent.top
            margins: Theme.paddingLarge
        }
        property int textWidth: Math.max(textLoader.width, info.width)
        property int mediaWidth: imageLoader.width || playerLoader.width || videoLoader.width || contactLoader.width || locationLoader.width
        width: Math.max(textWidth, mediaWidth)
        Component.onCompleted: {
            if (model.author === myJid) {
                anchors.right = parent.right
            }
            else {
                anchors.left = parent.left
            }
        }
        Loader {
            id: imageLoader
            active: false
            asynchronous: true
            sourceComponent: imageComponent
        }
        Loader {
            id: playerLoader
            active: false
            asynchronous: true
            sourceComponent: playerComponent
        }
        Loader {
            id: videoLoader
            active: false
            sourceComponent: videoComponent
        }
        Loader {
            id: contactLoader
            active: false
            sourceComponent: contactComponent
        }
        Loader {
            id: locationLoader
            active: false
            sourceComponent: locationComponent
        }
        Loader {
            id: textLoader
            active: false
            sourceComponent: textComponent
        }
        Row {
            id: info
            height: time.paintedHeight
            width: time.paintedWidth + deliveryStatus.width
            anchors.right: parent.right

            Label {
                id: time
                text: timestampToTime(model.timestamp)
                font.pixelSize: fontSize - 4
                color: down ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }

            Loader {
                id: deliveryStatus
                anchors.verticalCenter: parent.verticalCenter
                active: model.author == roster.myJid
                asynchronous: true
                sourceComponent: deliveryComponent
            }
        }
    }

    Component {
        id: deliveryComponent
        Item {
            id: deliveryItem
            width: model.msgstatus == 5 ? (msgSentTick.width * 1.5) : msgSentTick.width
            height: msgSentTick.height

            GlassItem {
                id: msgSentTick
                width: 16
                height: 16
                anchors.right: parent.right
                falloffRadius: 0.3
                radius: 0.4
                color: (model.msgstatus < 4) ? "#80ff0000" : "#80ffff00"
            }

            GlassItem {
                id: msgDeliveredTick
                width: 16
                height: 16
                anchors.left: parent.left
                falloffRadius: 0.3
                radius: 0.4
                color: "#8000ff00"
                visible: model.msgstatus == 5
            }
        }
    }

    Component {
        id: textComponent

        Label {
            id: message
            text: visible ? Utilities.linkify(Utilities.emojify(model.message, emojiPath), Theme.highlightColor) : ""
            textFormat: Text.RichText
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: fontSize
            color: down ? Theme.highlightColor : Theme.primaryColor
            onPaintedWidthChanged: changeMessageWidth()
        }
    }

    Component {
        id: imageComponent
        Item {
            id: imageItem
            width: prevWidth
            height: prevHeight
            property int prevWidth: (prev.status == Image.Ready) ? prev.width : Theme.itemSizeExtraLarge
            property int prevHeight: (prev.status == Image.Ready) ? prev.height : Theme.itemSizeExtraLarge

            Image {
                id: prev
                anchors.centerIn: parent
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                fillMode: Image.PreserveAspectFit
                source: getMediaPreview(model)
                sourceSize.width: maxWidth
                asynchronous: true
                cache: true
                clip: true
                smooth: true
                rotation: (model.localurl.length > 0) ? whatsapp.getExifRotation(model.localurl) : 0
            }

            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Medium
                running: visible
                visible: prev.status == Image.Loading
            }

            ProgressCircle {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.centerIn: parent
                visible: model.mediaprogress > 0 && model.mediaprogress < 100
                value: model.mediaprogress
            }

            IconButton {
                anchors.centerIn: parent
                icon.source: (model.mediaprogress > 0 && model.mediaprogress < 100) ? "image://theme/icon-m-clear" : "image://theme/icon-m-down"
                visible: model.localurl.length == 0
                onClicked: {
                    if (model.mediaprogress > 0 && model.mediaprogress < 100)
                        cancelMedia()
                    else
                        downloadMedia()
                }
            }
        }
    }

    Component {
        id: videoComponent
        Item {
            id: videoItem
            width: prevWidth
            height: prevHeight
            property int prevWidth: (vidprev.status == Image.Ready) ? vidprev.width : Theme.itemSizeExtraLarge
            property int prevHeight: (vidprev.status == Image.Ready) ? vidprev.height : Theme.itemSizeExtraLarge

            Image {
                id: vidprev
                anchors {
                    left: parent.left
                    top: parent.top
                }
                fillMode: Image.PreserveAspectFit
                source: getMediaPreview(model)
                sourceSize.width: maxWidth
                asynchronous: true
                cache: true
                clip: true
                smooth: true
                rotation: (model.localurl.length > 0) ? whatsapp.getExifRotation(model.localurl) : 0
            }

            Image {
                source: "image://theme/icon-m-play"
                visible: model.localurl.length > 0
                anchors.centerIn: parent
                asynchronous: true
                cache: true
            }

            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Medium
                running: visible
                visible: vidprev.status == Image.Loading
            }

            ProgressCircle {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.centerIn: parent
                visible: model.mediaprogress > 0 && model.mediaprogress < 100
                value: model.mediaprogress
            }

            IconButton {
                anchors.centerIn: parent
                icon.source: (model.mediaprogress > 0 && model.mediaprogress < 100) ? "image://theme/icon-m-clear" : "image://theme/icon-m-down"
                visible: model.localurl.length == 0
                onClicked: {
                    if (model.mediaprogress > 0 && model.mediaprogress < 100)
                        cancelMedia()
                    else
                        downloadMedia()
                }
            }
        }
    }

    Component {
        id: contactComponent
        Row {
            id: contactItem
            height: Theme.itemSizeMedium
            spacing: Theme.paddingLarge

            Image {
                id: contactImage
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.itemSizeMedium
                height: Theme.itemSizeMedium
                source: "image://theme/icon-m-service-generic"
                cache: true
            }

            Label {
                id: contactName
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.NoWrap
                text: model.medianame
                font.pixelSize: fontSize
            }
        }
    }

    Component {
        id: playerComponent
        Row {
            id: playerItem
            height: visible ? Theme.itemSizeMedium : 0
            property string source: whatsapp.checkIfExists(model.localurl)
            //onSourceChanged: player.source = whatsapp.checkIfExists(source)
            //Component.onCompleted: player.source = whatsapp.checkIfExists(source)

            MediaPlayer {
                id: player
                onDurationChanged: {
                    playerSeek.maximumValue = duration
                }
                onPositionChanged: {
                    playerSeek.value = position
                    playerSeek.valueText = Format.formatDuration(position / 1000, Format.DurationShort)
                }
            }

            IconButton {
                id: playButton
                anchors.verticalCenter: parent.verticalCenter
                icon.source: source.length > 0 ? (player.playbackState == Audio.PlayingState ? "image://theme/icon-m-pause"
                                                                                             : "image://theme/icon-m-play")
                                               : ((model.mediaprogress > 0 && model.mediaprogress < 100) ? "image://theme/icon-m-clear" : "image://theme/icon-m-down")
                onClicked: {
                    if (source.length > 0)
                    {
                        if (player.source !== source)
                            player.source = source
                        if (player.playbackState == Audio.PlayingState)
                            player.pause()
                        else
                            player.play()
                    }
                    else if (model.author !== roster.myJid) {
                        if (model.mediaprogress > 0 && model.mediaprogress < 100)
                            cancelMedia()
                        else
                            downloadMedia()
                    }
                }

                ProgressCircle {
                    anchors.fill: parent
                    visible: model.mediaprogress > 0 && model.mediaprogress < 100
                    value: model.mediaprogress
                }
            }

            Slider {
                id: playerSeek
                anchors.verticalCenter: parent.verticalCenter
                width: maxWidth - playButton.width
                minimumValue: 0
                maximumValue: 100
                stepSize: 1
                value: model.mediaprogress < 100 ? model.mediaprogress : 0
                enabled: source.length > 0
                onReleased: player.seek(value)
            }
        }
    }

    Component {
        id: locationComponent
        Image {
            id: locprev
            anchors.verticalCenter: parent.verticalCenter
            width: maxWidth
            height: Theme.itemSizeExtraLarge
            source: locationPreview(width, height, model.medialat, model.medialon, 14)
            asynchronous: true
            cache: true
            smooth: true

            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Medium
                running: visible
                visible: locprev.status == Image.Loading
            }
        }
    }

    Component {
        id: componentUrlMenu
        ContextMenu {
            id: urlMenu
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
                visible: conversationModel.getModelByMsgId(model.msgid).mediatype != 4
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
                text: qsTr("Delete")
                onClicked: {
                    if (model.mediaprogress > 0 && model.mediaprogress < 100)
                        whatsapp.cancelDownload(model.msgid, page.jid)
                    remove()
                }
            }
        }
    }

    Component {
        id: remorseComponent
        RemorseItem {}
    }

    Component {
        id: removeComponent
        RemoveAnimation {
            running: true
        }
    }
}
