import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: root

    Image {
        id: waimage
        source: "image://theme/harbour-mitakuuluu"
        anchors.centerIn: parent
        smooth: true
        onStatusChanged: {
            if (status == Image.Error)
                source = "/usr/share/icons/hicolor/86x86/apps/harbour-mitakuuluu.png"
        }
    }

    Label {
        id: wastatus
        text: roster.parseConnectionStatus(roster.connectionStatus)
        color: roster.parseConnectionColor(roster.connectionStatus)
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.right: root.right
        wrapMode: Text.WordWrap
        visible: roster.inStack
    }

    Label {
        id: wacount
        text: roster.inStack ? (roster.unreadCount > 1 ? (qsTr("Unread messages: %1").arg(roster.unreadCount)) : (roster.unreadCount == 1 ? qsTr("One unread message") : qsTr("No unread messages"))) : qsTr("Registration")
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.right: root.right
        wrapMode: Text.WordWrap
    }
}


