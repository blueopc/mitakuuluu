import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities


Dialog {
    id: page
    objectName: "broadcast"
    canAccept: listModel.count > 0
    allowedOrientations: Orientation.Portrait

    property variant jids: []

    onDone: {
        page.jids = []
        listModel.clear()
        textArea.text = ""
        mediaPath.text = ""
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: page

        PullDownMenu {
            MenuItem {
                text: "Add contact"
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
            title: "Send broadcast"
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
                    enabled: false
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                    }
                }

                Switch {
                    id: messageVoice
                    icon.source: "image://theme/icon-m-mic"
                    checked: false
                    enabled: false
                    onClicked: {
                        if (checked) {
                            mediaRow.hideAll()
                        }
                        checked = true
                    }
                }

                Switch {
                    id: messageContact
                    icon.source: "image://theme/icon-m-people"
                    checked: false
                    enabled: false
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

            TextArea {
                id: textArea
                visible: messageText.checked
                width: parent.width
                placeholderText: "Enter your message here..."
            }

            Label {
                id: mediaPath
                visible: messageMedia.checked
                font.pixelSize: Theme.fontSizeSmall
                width: parent.width
                wrapMode: Text.NoWrap
                elide: Text.ElideLeft

                function selectMedia(path) {
                    text = path
                }

                function unbindMedia() {
                    selectFile.selected.disconnect(mediaPath.selectMedia)
                    selectFile.done.disconnect(mediaPath.unbindMedia)
                }
            }

            Button {
                id: mediaSelect
                visible: messageMedia.checked
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Select media"
                onClicked: {
                    selectFile.processPath("/home/nemo")
                    selectFile.open()
                    selectFile.selected.connect(mediaPath.selectMedia)
                    selectFile.done.connect(mediaPath.unbindMedia)
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
                for (var i = 0; i < jids.length; i ++) {
                    var model = roster.getContactModel(jids[i])
                    var avatar = (typeof(model.avatar) != "undefined" && model.avatar != "undefined" && model.avatar.length > 0) ? model.avatar : ""
                    listModel.append({"jid": model.jid,
                                      "name": roster.getNicknameByJid(model.jid),
                                      "avatar": avatar})
                }
                selectContact.finished.disconnect(listView.selectionFinished)
            }
        }

        Label {
            anchors.fill: listView
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.secondaryHighlightColor
            font.bold: pArea.pressed
            visible: listModel.count == 0
            text: "Select «Add contact» menu item to select contacts"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap

            MouseArea {
                id: pArea
                anchors.fill: parent
                onClicked: addContacts.clicked()
            }
        }

        VerticalScrollDecorator {
            flickable: listView
        }
    }

    Component {
        id: listDelegate
        Rectangle {
            id: item
            width: parent.width - (Theme.paddingSmall * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            height: Theme.itemSizeMedium
            color: mArea.pressed ? Theme.secondaryHighlightColor : "transparent"

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingSmall
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
                color: mArea.pressed ? Theme.highlightColor : Theme.primaryColor
            }

            MouseArea {
                id: mArea
                anchors.fill: parent
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
