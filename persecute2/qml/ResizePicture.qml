import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    objectName: "resizePicture"
    allowedOrientations: Orientation.Portrait
    
    property string picture
    property int maximumSize
    property int minimumSize
    property bool avatar: true
    
    property string filename
    property string jid
    
    signal selected(string path)

    forwardNavigation: !pinch.pressed
    backNavigation: false

    onAccepted: {
        var temp = whatsapp.transformPicture(picture, jid, pinch.rectX, pinch.rectY, pinch.rectW, pinch.rectH, maximumSize, pinch.angle)
        page.selected(temp)
    }

    DialogHeader {
        id: title
        title: "Resize picture"
    }

    InteractionArea {
        id: pinch
        anchors.top: title.bottom
        width: page.width
        anchors.bottom: page.bottom
        avatar: page.avatar
        source: picture
        bucketMinSize: minimumSize
    }

    Rectangle {
        anchors.top: pinch.top
        anchors.right: parent.right
        anchors.margins: Theme.paddingMedium
        width: iconButton.width
        height: iconButton.height
        radius: width / 2
        color: iconButton.pressed ? "#40FFFFFF" : "#20FFFFFF"
        IconButton {
            id: iconButton
            icon.source: "image://theme/icon-m-refresh"
            highlighted: pressed
            onClicked: {
                pinch.rotate()
            }
        }
    }
}
