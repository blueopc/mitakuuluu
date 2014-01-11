import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "profilePage"

    property string jid: ""
    property string pushname: ""
    property string presence: ""
    property string phone: ""
    property string picture: ""
    property bool blocked: false

    Connections {
        target: roster.contacts
        onNicknameChanged: {
            if (pjid == page.jid) {
                pushname = nickname
            }
        }
    }

    Connections {
        target: whatsapp

        onPictureUpdated: {
            if (pjid == page.jid) {
                picture = ""
                picture = path
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {

        }
        else if (status == PageStatus.Active) {
            phone = jid.split("@")[0]
            var model = roster.getContactModel(page.jid)
            pushname = model.nickname
            presence = model.message
            picture = model.avatar
            blocked = model.blocked
        }
    }

    function timestampToFullDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM yyyy")
    }

    PageHeader {
        id: header
        title: pushname
    }

    SilicaFlickable {
        id: flick
        anchors.top: header.bottom
        anchors.bottom: page.bottom
        anchors.bottomMargin: Theme.paddingSmall
        anchors.left: page.left
        anchors.leftMargin: Theme.paddingMedium
        anchors.right: page.right
        anchors.rightMargin: Theme.paddingMedium
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge * 4
                height: Theme.iconSizeLarge * 4
                anchors.horizontalCenter: parent.horizontalCenter
                source: page.picture

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        avatarView.show(page.picture)
                    }
                }
            }

            Label {
                id: pushnameLabel
                width: parent.width
                text: qsTr("Nickname: %1").arg(Utilities.emojify(pushname, emojiPath))
                textFormat: Text.RichText
            }

            Label {
                id: presenceLabel
                width: parent.width
                text: qsTr("Status: %1").arg(Utilities.emojify(presence, emojiPath))
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
            }

            Label {
                id: phoneLabel
                width: parent.width
                text: qsTr("Phone: +%1").arg(phone)
                textFormat: Text.RichText
            }

            Label {
                id: ifBlocked
                width: parent.width
                text: qsTr("Contact blocked")
                visible: page.blocked
            }

            Button {
                id: blockButton
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: roster.connectionStatus == 4
                text: blocked ? qsTr("Unblock contact") : qsTr("Block contact")
                onClicked: {
                    page.blocked = !page.blocked
                    whatsapp.blockOrUnblockContact(page.jid)
                }
            }

            Button {
                id: saveButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save to phonebook")
                onClicked: {
                    whatsapp.openProfile(pushname, "+" + phone)
                }
            }

            Button {
                id: saveChatButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save chat history to file")
                onClicked: {
                    conversationPage.saveHistory(page.jid, page.pushname)
                }
            }
        }
    }

    VerticalScrollDecorator {
        flickable: flick
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
}
