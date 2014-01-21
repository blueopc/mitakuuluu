import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: selectMedia

    signal mediaSelected(string file)

    function sendMediaImage() {
        mediaSelected(selectPicture.selectedPath)
        unbindMediaImage()
    }

    function unbindMediaImage() {
        selectPicture.accepted.disconnect(selectMedia.sendMediaImage)
        selectPicture.rejected.disconnect(selectMedia.unbindMediaImage)
    }

    function unbindMediaFile() {
        selectFile.selected.disconnect(selectMedia.sendMedia)
        selectFile.done.disconnect(selectMedia.unbindMediaFile)
    }

    SilicaFlickable {
        id: mFlick
        anchors.fill: parent
        property int itemWidth: width / 2
        property int itemHeight: (height / 2) - (mHeader.height / 2)

        PageHeader {
            id: mHeader
            title: qsTr("Select media type")
        }

        SquareButton {
            anchors.left: parent.left
            anchors.top: mHeader.bottom
            width: mFlick.itemWidth
            height: mFlick.itemHeight
            icon.source: "image://theme/icon-m-image"
            onClicked: {
                selectPicture.accepted.connect(selectMedia.sendMediaImage)
                selectPicture.setProcessImages()
                selectPicture.open(true)
                selectPicture.rejected.connect(selectMedia.unbindMediaImage)
            }
        }

        SquareButton {
            anchors.right: parent.right
            anchors.top: mHeader.bottom
            width: mFlick.itemWidth
            height: mFlick.itemHeight
            icon.source: "image://theme/icon-m-video"
            onClicked: {
                selectFile.processPath("/home/nemo", qsTr("Select video"))
                selectFile.setFilter(["*.mp4", "*.avi", "*.mov"])
                pageStack.replace(selectFile)
                selectFile.selected.connect(selectMedia.mediaSelected)
                selectFile.done.connect(selectMedia.unbindMediaFile)
            }
        }

        SquareButton {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: mFlick.itemWidth
            height: mFlick.itemHeight
            icon.source: "image://theme/icon-m-music"
            onClicked: {
                selectFile.processPath("/home/nemo", qsTr("Select audio"))
                selectFile.setFilter(["*.mp3", "*.aac", "*.flac", "*.wav"])
                pageStack.replace(selectFile)
                selectFile.selected.connect(selectMedia.mediaSelected)
                selectFile.done.connect(selectMedia.unbindMediaFile)
            }
        }
    }
}
