import QtQuick 2.0
import Sailfish.Silica 1.0

ImageBase {

    Image {
        id: thumbnail
        property bool gridMoving: grid.moving

        source: parent.source
        width:  size
        height: size
        sourceSize.width: width
        sourceSize.height: height
        y: contentYOffset
        x: contentXOffset

        cache: true
        asynchronous: true
        smooth: true
        fillMode: Image.PreserveAspectCrop

        onStatusChanged: {
            if (status == Image.Error) {
                errorLabelComponent.createObject(thumbnail)
            }
        }
    }

    Component {
        id: errorLabelComponent
        Label {
            //: Thumbnail Image loading failed
            //% "Oops, can't display the thumbnail!"
            text: qsTrId("components_gallery-la-image-thumbnail-loading-failed")
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.paddingMedium
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
