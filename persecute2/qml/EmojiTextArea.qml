import QtQuick 2.0
import Sailfish.Silica 1.0

TextArea {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right

    textLeftMargin: showEmoji ? Theme.itemSizeSmall : Theme.paddingLarge
    textRightMargin: showAction ? Theme.itemSizeSmall: Theme.paddingLarge

    property bool showEmoji: false
    property bool showAction: false

    property alias actionButton: sendButton

    property alias emojiChecked: emojiButton.checked
    signal action
    signal emojiClicked

    Rectangle {
        id: emojiButton
        width: Theme.itemSizeExtraSmall
        height: width
        radius: width / 2
        border.width: 2
        border.color: checked ? Theme.secondaryHighlightColor : Theme.secondaryColor
        color: "transparent"
        property bool checked: false

        anchors.top: parent.top
        anchors.topMargin: - Theme.paddingSmall
        anchors.left: parent.left
        anchors.leftMargin: - Theme.itemSizeExtraSmall
        visible: showEmoji

        MouseArea {
            anchors.fill: parent
            onClicked: {
                emojiButton.checked = !emojiButton.checked
                root.emojiClicked()
            }
        }
    }

    IconButton {
        id: sendButton
        icon.source: "image://theme/icon-m-message"
        highlighted: enabled
        anchors.top: parent.top
        anchors.topMargin: - Theme.paddingSmall
        anchors.right: parent.right
        anchors.rightMargin: - Theme.itemSizeExtraSmall
        visible: showAction
        onClicked: {
            root.action()
        }
    }
}
