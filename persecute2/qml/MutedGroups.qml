import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "mutedGroups"

    onStatusChanged: {
        if (status === PageStatus.Inactive) {
            listModel.clear()
        }
        else if (status == PageStatus.Activating) {
            whatsapp.getMutedGroups()
        }
    }

    Connections {
        target: whatsapp
        onGroupsMuted: {
            listModel.clear()
            for (var i = 0; i < jids.length; i++) {
                var jid = jids[i]
                var model = roster.getContactModel(jid)
                if (model.jid) {
                    listModel.append({"jid": model.jid,
                                      "name": roster.getNicknameByJid(model.jid),
                                      "avatar": model.avatar})
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
                text: qsTr("Add group")
                onClicked: {
                    selectContact.hideGroups = false
                    selectContact.hideContacts = true
                    selectContact.contactsChanged()
                    selectContact.finished.connect(listView.selectionFinished)
                    selectContact.select(listModel)
                    selectContact.open()
                }
            }
        }

        header: PageHeader {
            id: title
            title: qsTr("Muted groups")
        }

        function selectionFinished() {
            var jids = selectContact.jids
            whatsapp.muteGroups(jids)
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
        text: qsTr("No muted groups")
        visible: listView.count == 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
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
                anchors.leftMargin: Theme.paddingSmall
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
                    whatsapp.muteOrUnmuteGroup(model.jid)
                    listModel.remove(index)
                }
            }
        }
    }
}
