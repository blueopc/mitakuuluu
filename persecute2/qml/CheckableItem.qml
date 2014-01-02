import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    height: label.paintedHeight
    width: parent.width

    property alias checked: checkable.checked
    property alias text: label.text

    Switch {
        id: checkable
        anchors.verticalCenter: label.verticalCenter
        anchors.left: root.left
        checked: false
    }

    Label {
        id: label
        anchors.left: checkable.right
        //anchors.leftMargin: Theme.paddingMedium
        anchors.verticalCenter: root.verticalCenter
        font.pixelSize: Theme.fontSizeSmall
    }

    MouseArea {
        anchors.fill: root
        onClicked: root.checked = !root.checked
    }
}
