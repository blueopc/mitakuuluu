import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "privacyList"

    onStatusChanged: {
        if (status === PageStatus.Inactive) {
            listModel.clear()
        }
        else if (status == PageStatus.Activating) {
            whatsapp.getPrivacyList()
        }
    }

    Connections {
        target: whatsapp
        onContactsBlocked: {
            listModel.clear()
            for (var i = 0; i < list.length; i++) {
                var jid = list[i]
                var model = roster.getContactModel(jid)
                if (model.jid) {
                    listModel.append({"jid": model.jid,
                                      "name": roster.getNicknameByJid(model.jid),
                                      "avatar": model.avatar})
                }
                else {
                    listModel.append({"jid": jid,
                                      "name": jid.split("@")[0],
                                      "avatar": ""})
                }
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: page
        clip: true
        model: listModel
        delegate: listDelegate

        PullDownMenu {
            MenuItem {
                text: qsTr("Add number")
                onClicked: {
                    addDialog.open()
                    addNumber.forceActiveFocus()
                }
            }

            MenuItem {
                text: qsTr("Select contacts")
                onClicked: {
                    selectContact.hideGroups = true
                    selectContact.hideContacts = false
                    selectContact.contactsChanged()
                    selectContact.finished.connect(listView.selectionFinished)
                    selectContact.select(listModel)
                    selectContact.open()
                }
            }
        }

        header: PageHeader {
            id: title
            title: qsTr("Blacklist")
        }

        function selectionFinished() {
            listModel.clear()
            var jids = selectContact.jids
            for (var i = 0; i < jids.length; i ++) {
                var model = roster.getContactModel(jids[i])
                var avatar = (typeof(model.avatar) != "undefined" && model.avatar != "undefined" && model.avatar.length > 0) ? model.avatar : ""
                listModel.append({"jid": model.jid,
                                  "name": roster.getNicknameByJid(model.jid),
                                  "avatar": avatar})
            }
            whatsapp.sendBlockedJids(jids)
            selectContact.finished.disconnect(listView.selectionFinished)
        }
    }

    VerticalScrollDecorator {
        flickable: listView
    }

    Label {
        anchors.fill: listView
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeMedium
        text: qsTr("Blacklist is empty")
        visible: listView.count == 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }

    Dialog {
        id: addDialog
        canAccept: addNumber.text.trim().length > 0
        onDone: {
            addNumber.focus = false
            page.forceActiveFocus()
        }
        onAccepted: {
            var bjid = text + "@s.whatsapp.net"
            var exists = false
            for (var i = 0; i < listModel.count; i++) {
                if (listModel.get(i).jid === bjid) {
                    exists = true
                    break
                }
            }
            if (!exists)
                whatsapp.blockOrUnblockContact(bjid)
        }

        DialogHeader {
            title: qsTr("Add to blacklist")
        }

        Label {
            text: "+"
            anchors.top: addNumber.top
            anchors.topMargin: Theme.paddingSmall
            anchors.right: addNumber.left
            anchors.rightMargin: - Theme.paddingLarge
        }

        TextField {
            id: addNumber
            width: parent.width - (Theme.paddingLarge * 2)
            anchors.centerIn: parent
            placeholderText: qsTr("1234567890")
            validator: RegExpValidator{ regExp: /[0-9]*/;}
            inputMethodHints: Qt.ImhDialableCharactersOnly
            EnterKey.enabled: false
        }
    }

    ListModel {
        id: listModel
    }

    Component {
        id: listDelegate
        Rectangle {
            id: item
            width: parent.width - Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            height: Theme.itemSizeMedium
            color: mArea.pressed ? Theme.secondaryHighlightColor : "transparent"

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: contact
                anchors.left: contactava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: contactava.verticalCenter
                anchors.right: remove.left
                anchors.rightMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.name, emojiPath)
                truncationMode: TruncationMode.Fade
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
                    whatsapp.blockOrUnblockContact(model.jid)
                    listModel.remove(index)
                }
            }
        }
    }
}
