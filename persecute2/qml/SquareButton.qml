import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: root

    property alias icon: image
    signal clicked

    color: "transparent"
    border.width: 2
    border.color: mArea.pressed ? Theme.highlightColor : Theme.secondaryHighlightColor

    Image {
        id: image
        smooth: true
        anchors.centerIn: root
        fillMode: Image.PreserveAspectFit
        cache: true
    }

    MouseArea {
        id: mArea
        anchors.fill: root
        onClicked: {
            root.clicked()
        }
    }
}
