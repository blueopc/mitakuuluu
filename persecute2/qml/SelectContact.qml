import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    objectName: "selectContact"
    allowedOrientations: Orientation.Portrait

    property string jid: ""
    property variant jids: []
    property bool hideGroups: false
    property bool hideContacts: false

    signal added(string pjid)
    signal removed(string pjid)
    signal finished

    function select(participants) {
        for (var i = 0; i < participants.count; i ++) {
            var model = participants.get(i)
        	var value = page.jids
            value.splice(0, 0, model.jid)
            page.jids = value
        }
    }

    onAccepted: page.finished()

    onStatusChanged: {
        if(status === DialogStatus.Closed) {
            page.jids = []
            page.jid = ""
            contactsModel.clear()
            hideGroups = false
            hideContacts = false
        }
    }

    function contactsChanged() {
    	contactsModel.contactsChanged()
    }

    DialogHeader {
        id: title
        title: qsTr("Select contact")
    }

    SilicaListView {
    	id: listView
        anchors.fill: page
        anchors.topMargin: title.height + Theme.paddingSmall
        model: contactsModel
        delegate: contactsDelegate
        clip: true
    }

    VerticalScrollDecorator {
        flickable: listView
    }

    ContactsModel {
        id: contactsModel
    }

    Component {
        id: contactsDelegate

        Rectangle {
            id: item
            width: parent.width
            height: model.jid.indexOf("-") != -1 ? (hideGroups ? 0 : Theme.itemSizeMedium) : ((model.jid == roster.myJid || hideContacts) ? 0 : Theme.itemSizeMedium)
            visible: height > 0
            color: checked ? Theme.secondaryHighlightColor : (mArea.pressed ? Theme.secondaryHighlightColor : "transparent")
            property bool checked: page.jids.indexOf(model.jid) != -1

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: nickname
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.nickname, emojiPath)
                anchors.left: ava.right
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: (mArea.pressed || checked) ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: status
                font.pixelSize: Theme.fontSizeSmall
                text: model.contacttype == 0 ? Utilities.emojify(model.message, emojiPath) : qsTr("Group chat")
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: (mArea.pressed || checked) ? Theme.secondaryHighlightColor : Theme.secondaryColor
                truncationMode: TruncationMode.Fade
            }

            MouseArea {
                id: mArea
                anchors.fill: parent
                onClicked: {
                    var value = page.jids
                    var exists = value.indexOf(model.jid)
                    if (exists != -1) {
                        value.splice(exists, 1)
                        page.removed(model.jid)
                    }
                    else {
                        value.splice(0, 0, model.jid)
                        page.added(model.jid)
                    }
                    page.jids = value
                }
            }
        }
    }
}
