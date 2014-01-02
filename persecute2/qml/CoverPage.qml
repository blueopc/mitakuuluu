import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: root

    Image {
        id: waimage
        source: "/usr/share/icons/hicolor/86x86/apps/harbour-mitakuuluu.png"
        anchors.centerIn: parent
        smooth: true
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
        text: roster.inStack ? (roster.unreadCount > 0 ? ("Unread messages: " + roster.unreadCount) : "No unread messages") : "Registration"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.right: root.right
        wrapMode: Text.WordWrap
    }
}


