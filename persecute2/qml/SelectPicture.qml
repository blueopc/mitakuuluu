import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0

Dialog {
    id: page
    objectName: "selectFile"
    allowedOrientations: Orientation.Portrait
    canAccept: selectedPath.length > 0

    property string selectedPath: ""
    signal selected(string path)

    DialogHeader {
        id: title
        title: qsTr("Select picture")
    }

    function setProcessImages() {
        var filters = ["*.jpg", "*.JPG", "*.jpeg", "*.JPEG", "*.png", "*.PNG", "*.gif", "*.GIF"]
        var dirs = ["/home/nemo/"]
        files.filter = filters
        files.showRecursive(dirs)
    }

    onStatusChanged: {
        if (page.status == DialogStatus.Opened) {
            selectedPath = ""
        }
    }

    onDone: {
        files.clear()
    }

    FilesModel {
        id: files
    }

    SilicaGridView {
        id: view
        clip: true
        anchors.top: title.bottom
        anchors.bottom: page.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        cellWidth: page.isPortrait ? (page.width / 4) : (page.width / 7)
        cellHeight: cellWidth
        cacheBuffer: cellHeight * 2

        model: files

        delegate: Item {
            width: view.cellWidth - 1
            height: view.cellHeight - 1

            Image {
                id: image
                source: model.path
                height: parent.height
                width: parent.width
                sourceSize.height: parent.height
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectCrop
                clip: true
                smooth: true
                cache: true
                asynchronous: true
                rotation: whatsapp.getExifRotation(model.path)

                states: [
                    State {
                        name: 'loaded'; when: image.status == Image.Ready
                        PropertyChanges { target: image; opacity: 1; }
                    },
                    State {
                        name: 'loading'; when: image.status != Image.Ready
                        PropertyChanges { target: image; opacity: 0; }
                    }
                ]

                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.highlightColor
                visible: model.path == page.selectedPath
                opacity: 0.5
            }
            Rectangle {
                id: rec
                color: Theme.secondaryHighlightColor
                height: Theme.fontSizeExtraSmall
                width: parent.width
                anchors.bottom: parent.bottom
                opacity: mArea.pressed ? 1.0 : 0.6
            }
            Label {
                anchors.fill: rec
                anchors.margins: 3
                //height: 26
                font.pixelSize: Theme.fontSizeExtraSmall
                text: model.name
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                horizontalAlignment : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Theme.primaryColor
            }

            MouseArea {
                id: mArea
                anchors.fill: parent
                onClicked: {
                    if (page.selectedPath == model.path)
                        page.selectedPath = ""
                    else
                        page.selectedPath = model.path
                }
            }
        }
    }

    VerticalScrollDecorator {
        flickable: view
    }
}
