import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    objectName: "broadcast"
    onStatusChanged: {
        if (page.status == DialogStatus.Open) {
            page.canAccept = false
        }
    }

    onAccepted: {
        if (messageText.checked) {
            whatsapp.sendBroadcast(page.jids, textArea.text)
        }
        else if (messageMedia.checked || messageVoice.checked) {
            whatsapp.sendMedia(page.jids, mediaPath.text)
        }
        else if (messageLocation.checked) {
            whatsapp.sendLocation(page.jids, location.longitude, location.latitude, location.zoom, location.googlemaps)
        }
        else if (messageContact.checked) {
            whatsapp.sendVCard(page.jids, mediaPath.text, avatarContact.data)
        }

        clear()
    }

    onRejected: {
        clear()
    }

    property variant jids: []

    function clear() {
        mediaRow.hideAll()
        page.jids = []
        listModel.clear()
        textArea.text = ""
        mediaPath.text = ""
        mediaPath.data = ""
        location.latitude = 55.159479
        location.longitude = 61.402796
        location.zoom = 15
        location.googlemaps = false
        location.source = ""
    }

    function openMedia(path) {
        mediaRow.hideAll()
        messageMedia.checked = true
        mediaPath.text = path
        page.open()
    }

    function openRecording(path) {
        mediaRow.hideAll()
        messageVoice.checked = true
        mediaPath.text = path
        page.open()
    }

    function openLocation(latitude, longitude, zoom, googlemaps) {
        mediaRow.hideAll()
        messageLocation.checked = true
        location.latitude = latitude
        location.longitude = longitude
        location.zoom = zoom
        location.googlemaps = googlemaps
        location.loadPreview()
        page.open()
    }

    function openVCard(name, data) {
        mediaRow.hideAll()
        messageContact.checked = true
        mediaPath.text = name
        mediaPath.data = data
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: page

        PullDownMenu {
            MenuItem {
                text: qsTr("Add contact")
                onClicked: {
                    selectContact.hideGroups = true
                    selectContact.contactsChanged()
                    selectContact.finished.connect(listView.selectionFinished)
                    selectContact.select(listModel)
                    selectContact.open()
                }
            }
        }

        DialogHeader {
            id: title
            title: qsTr("Send broadcast")
        }


        Item {
            id: switchArea
            anchors.left: parent.left
            width: page.isPortrait ? page.width : (page.width / 2)
            anchors.top: title.bottom
            anchors.topMargin: Theme.paddingSmall
            height: mediaRow.height
            Row {
                id: mediaRow
                anchors.horizontalCenter: parent.horizontalCenter

                function hideAll() {
                    messageText.checked = false
                    messageMedia.checked = false
                    messageLocation.checked = false
                    messageVoice.checked = false
                    messageContact.checked = false
                }

                Switch {
                    id: messageText
                    icon.source: "image://theme/icon-m-message"
                    checked: true
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                    }
                }

                Switch {
                    id: messageMedia
                    icon.source: "image://theme/icon-m-media"
                    checked: false
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                    }
                }

                Switch {
                    id: messageLocation
                    icon.source: "image://theme/icon-m-gps"
                    checked: false
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                        positionSource = positionSourceComponent.createObject(null)
                    }
                }

                Switch {
                    id: messageVoice
                    icon.source: "image://theme/icon-m-mic"
                    checked: false
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                        recorder = recorderComponent.createObject(null)
                        player = playerComponent.createObject(null)
                    }
                }

                Switch {
                    id: messageContact
                    icon.source: "image://theme/icon-m-people"
                    checked: false
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                    }
                }
            }
        }

        Column {
            id: contentMedia
            anchors.top: switchArea.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.left: parent.left
            width: page.isPortrait ? page.width : (page.width / 2)

            EmojiTextArea {
                id: textArea
                visible: messageText.checked
                width: parent.width
                placeholderText: qsTr("Enter your message here...")
                background: null
            }

            Label {
                id: mediaPath
                visible: messageMedia.checked || messageVoice.checked || messageContact.checked
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                wrapMode: Text.NoWrap
                elide: Text.ElideLeft
                property string data

                function selectMedia(path) {
                    text = path
                }

                function unbindMedia() {
                    selectFile.selected.disconnect(mediaPath.selectMedia)
                    selectFile.done.disconnect(mediaPath.unbindMedia)
                }

                function selectMediaImage() {
                    selectMedia(selectPicture.selectedPath)
                    unbindMediaImage()
                }

                function unbindMediaImage() {
                    selectPicture.accepted.disconnect(page.selectMediaImage)
                    selectPicture.rejected.disconnect(page.unbindMediaImage)
                }
            }

            Image {
                id: location
                width: 320
                height: 320
                anchors.horizontalCenter: parent.horizontalCenter
                property bool googlemaps: false
                property real latitude: 55.159479
                property real longitude: 61.402796
                property int zoom: 15
                visible: messageLocation.checked
                function loadPreview() {
                    if (googlemaps)
                        source = "http://maps.googleapis.com/maps/api/staticmap?zoom=" + zoom
                                    + "&size=320x320"
                                    +"&maptype=roadmap&sensor=false&markers=color:red|label:.|"
                                    + latitude
                                    + ","
                                    + longitude
                    else
                        source = "http://m.nok.it/?ctr="
                                    + latitude
                                    + ","
                                    + longitude
                                    + "&w=320"
                                    + "&h=320"
                                    + "&poix0="
                                    + latitude
                                    + ","
                                    + longitude
                                    + ";red;white;20;.;"
                                    + "&z=" + zoom
                                    + "&nord&f=0&poithm=1&poilbl=0"
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.secondaryHighlightColor
                    visible: location.status != Image.Ready

                    Label {
                        text: qsTr("press to locate")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.fill: parent
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.visible
                    onClicked: {
                        roster.locateAndSend()
                    }
                }

                BusyIndicator {
                    anchors.centerIn: location
                    running: visible
                    visible: location.status != Image.Ready
                    size: BusyIndicatorSize.Large
                }
            }

            Button {
                id: mediaSelect
                visible: messageMedia.checked
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Select media")
                onClicked: {
                    pageStack.push(selectMedia)
                }
            }

            Button {
                id: voiceSelect
                visible: messageVoice.checked
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Record")
                onClicked: {
                    roster.recordAndSend()
                }
            }

            Button {
                id: contactSelect
                visible: messageContact.checked
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Contacts")
                onClicked: {
                    roster.selectSendContact()
                }
            }
        }

        SilicaListView {
            id: listView
            anchors.top: page.isPortrait ? contentMedia.bottom : title.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: page.isPortrait ? page.width : (page.width / 2)
            clip: true
            model: listModel
            delegate: listDelegate

            function selectionFinished() {
                listModel.clear()
                var jids = selectContact.jids
                page.jids = jids
                for (var i = 0; (i < jids.length && listView.count < 51); i ++) {
                    var model = roster.getContactModel(jids[i])
                    var avatar = (typeof(model.avatar) != "undefined" && model.avatar != "undefined" && model.avatar.length > 0) ? model.avatar : ""
                    listModel.append({"jid": model.jid,
                                      "name": roster.getNicknameByJid(model.jid),
                                      "avatar": avatar})
                    if (listView.count == 50) {
                        banner.notify(qsTr("Max broadcast recepients count reached"))
                    }
                }
                selectContact.finished.disconnect(listView.selectionFinished)
            }
            onCountChanged: page.canAccept = (count > 0)
        }

        Label {
            anchors.fill: listView
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.secondaryHighlightColor
            font.bold: pArea.pressed
            visible: listModel.count == 0
            text: qsTr("Select &quot;Add contact&quot; menu item to select contacts")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            textFormat: Text.RichText

            MouseArea {
                id: pArea
                anchors.fill: parent
                onClicked: menuPeek.start()
            }

            SequentialAnimation {
                id: menuPeek
                PropertyAction {
                    target: flickable.pullDownMenu
                    property: "active"
                    value: true
                }
                NumberAnimation {
                    target: flickable
                    property: "contentY"
                    to: 0 - 30
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: flickable
                    property: "contentY"
                    to: 0
                    duration: 80
                    easing.type: Easing.OutCubic
                }
                PropertyAction {
                    target: flickable.pullDownMenu
                    property: "active"
                    value: false
                }
            }
        }

        VerticalScrollDecorator {
            flickable: listView
        }
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
                    selectPicture.accepted.connect(page.selectMediaImage)
                    selectPicture.rejected.connect(page.unbindMediaImage)
                    selectPicture.setProcessImages()
                    selectPicture.open(true)
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
                    selectFile.selected.connect(mediaPath.selectMedia)
                    selectFile.done.connect(mediaPath.unbindMedia)
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
                    selectFile.selected.connect(mediaPath.selectMedia)
                    selectFile.done.connect(mediaPath.unbindMedia)
                }
            }
        }
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: contact
                anchors.left: contactava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: remove.left
                anchors.rightMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.name, emojiPath)
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            IconButton {
                id: remove
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-clear"
                onClicked: {
                    listModel.remove(index)
                }
            }
        }
    }

    ListModel {
        id: listModel
    }
}
