import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    property string source
    property variant content

    PageHeader {
        id: header
        title: qsTr("WhatsappShare")
    }

    Column {
        width: root.width
        anchors.top: header.bottom
        anchors.bottom: root.bottom
        spacing: Theme.paddingLarge

        Label {
            text: source
            width: parent.width
            wrapMode: Text.WrapAnywhere
        }

        Label {
            text: JSON.stringify(content)
            width: parent.width
            wrapMode: Text.WrapAnywhere
        }
    }
}
