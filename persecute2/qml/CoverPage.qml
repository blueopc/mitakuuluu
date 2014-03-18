import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: root

    Image {
        id: bgimg
        source: "../images/cover.png"
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: sourceSize.height * width / sourceSize.width
    }

    Label {
        id: wastatus
        text: roster.parseConnectionStatus(roster.connectionStatus)
        color: roster.parseConnectionColor(roster.connectionStatus)
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: parent.top
        anchors.margins: Theme.paddingLarge
        wrapMode: Text.WordWrap
        visible: roster.inStack
    }

    Label {
        id: wacount
        text: roster.inStack ? (roster.unreadCount > 1 ? (qsTr("Unread messages: %1").arg(roster.unreadCount)) : (roster.unreadCount == 1 ? qsTr("One unread message") : qsTr("No unread messages"))) : qsTr("Registration")
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.leftMargin: Theme.paddingSmall
        anchors.right: root.right
        anchors.rightMargin: Theme.paddingSmall
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (roster.inStack ? (parent.height / 1.8) : (parent.height / 4.5)) - height
        wrapMode: Text.WordWrap
    }

    CoverActionList {
        enabled: roster.inStack

        CoverAction {
            iconSource: coverIconLeft
            onTriggered: coverLeftClicked()
        }

        CoverAction {
            iconSource: coverIconRight
            onTriggered: coverRightClicked()
        }
    }
}
