import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0


Dialog {
    id: page
    objectName: "selectFile"
    allowedOrientations: Orientation.Portrait

    signal selected(string path)

    function processPath(path) {
        mediaImage.checked = true
        mediaMusic.checked = false
        mediaVideo.checked = false
        header.subtitle = path
        filesModel.filter = ["*.png", "*.jpg", "*.gif"]
        filesModel.path = path
    }

    DialogHeader {
        id: header
        title: " "
        property alias subtitle: subtitleLabel.text
    }

    Label {
        id: headerLabel
        anchors.top: page.top
        anchors.topMargin: Theme.paddingMedium
        anchors.horizontalCenter: page.horizontalCenter
        text: "Select file"
        color: Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeLarge
            family: Theme.fontFamilyHeading
        }
    }

    Label {
        id: subtitleLabel
        anchors.right: page.right
        anchors.rightMargin: header.height - Theme.paddingLarge
        anchors.left: page.left
        anchors.leftMargin: header.height - Theme.paddingLarge
        anchors.top: headerLabel.bottom
        color: Theme.secondaryColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        font {
            pixelSize: Theme.fontSizeExtraSmall
            family: Theme.fontFamily
        }
    }

    Rectangle {
        width: Theme.iconSizeLarge
        height: Theme.iconSizeLarge
        radius: Theme.iconSizeLarge / 2
        anchors.top: headerLabel.top
        anchors.left: page.left
        anchors.leftMargin: header.height - Theme.paddingLarge
        border.color: dArea.pressed ? "#80FFFFFF" : "#40FFFFFF"
        border.width: 1
        color: "transparent"
        Image {
            anchors.centerIn: parent
            width: Theme.iconSizeMedium
            height: Theme.iconSizeMedium
            smooth: true
            source: "image://theme/icon-m-" + (mediaImage.checked ? "image" : (mediaMusic.checked ? "music" : "video"))
        }
        MouseArea {
            id: dArea
            anchors.fill: parent
            onClicked: {
                if (panel.open)
                    panel.hide()
                else
                    panel.show()
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.top: header.bottom
        anchors.left: page.left
        anchors.right: page.right
        anchors.bottom: page.bottom
        clip: true
        model: filesModel
        delegate: filesDelegate
    }

    FilesModel {
        id: filesModel
        sorting: false
    }

    Component {
        id: filesDelegate
        Rectangle {
            id: item
            width: ListView.view.width
            height: Theme.itemSizeSmall
            color: mArea.pressed ? Theme.secondaryHighlightColor : "transparent"

            Image {
                id: icon
                source: "image://theme/icon-m-" + (model.dir ? "folder" : "other")
                cache: true
                asynchronous: false
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingSmall
            }

            Label {
                id: file
                text: model.name
                anchors.left: icon.right
                anchors.leftMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeSmall
            }

            MouseArea {
                id: mArea
                anchors.fill: parent
                onClicked: {
                    if (model.dir) {
                        header.subtitle = model.path
                        filesModel.path = model.path
                    }
                    else {
                        page.selected(model.path)
                        page.accept()
                    }
                }
            }
        }
    }

    VerticalScrollDecorator {
        flickable: listView
    }

    DockedPanel {
        id: panel
        dock: Dock.Bottom
        width: parent.width
        height: Theme.itemSizeExtraLarge + Theme.paddingLarge

        Row {
            id: mediaRow
            anchors.centerIn: parent

            Switch {
                id: mediaImage
                icon.source: "image://theme/icon-l-image"
                checked: true
                onClicked: {
                    if (checked) {
                        mediaVideo.checked = false
                        mediaMusic.checked = false
                        var filters = ["*.png", "*.jpg", "*.gif"]
                        filesModel.filter = filters
                        filesModel.processPath(filesModel.path)
                    }
                    else {
                        checked = true
                    }
                    panel.hide()
                }
            }

            Switch {
                id: mediaVideo
                icon.source: "image://theme/icon-l-video"
                checked: false
                onClicked: {
                    if (checked) {
                        mediaImage.checked = false
                        mediaMusic.checked = false
                        var filters = ["*.mp4", "*.avi", "*.mov"]
                        filesModel.filter = filters
                        filesModel.processPath(filesModel.path)
                    }
                    else {
                        checked = true
                    }
                    panel.hide()
                }
            }

            Switch {
                id: mediaMusic
                icon.source: "image://theme/icon-l-music"
                checked: false
                onClicked: {
                    if (checked) {
                        mediaVideo.checked = false
                        mediaImage.checked = false
                        var filters = ["*.mp3", "*.aac", "*.flac", "*.wav"]
                        filesModel.filter = filters
                        filesModel.processPath(filesModel.path)
                    }
                    else {
                        checked = true
                    }
                    panel.hide()
                }
            }
        }
    }
}
