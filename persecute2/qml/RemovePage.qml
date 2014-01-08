import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "removePage"
    property bool processing: true

    Connections {
        target: roster.contacts
        onDeleteEverythingSuccessful: {
            processing = false
        }
    }

    BusyIndicator {
        anchors.centerIn: page
        size: BusyIndicatorSize.Large
        running: visible
        visible: page.status == PageStatus.Active && processing
    }

    Button {
        anchors.centerIn: page
        text: qsTr("Quit")
        visible: page.status == PageStatus.Active && !processing
        onClicked: {
            whatsapp.shutdown()
            Qt.quit()
        }
    }
}
