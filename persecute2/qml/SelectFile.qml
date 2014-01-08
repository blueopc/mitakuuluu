import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0


Page {
    id: page
    objectName: "selectFile"

    signal selected(string path)
    signal done

    onStatusChanged: {
        if (status == PageStatus.Inactive)
            page.done()
    }

    function setFilter(filter) {
        filesModel.filter = filter
    }

    function processPath(path, title) {
        headerLabel.text = title
        header.subtitle = path
        filesModel.path = path
    }

    PageHeader {
        id: header
        title: " "
        property alias subtitle: subtitleLabel.text
    }

    Label {
        id: headerLabel
        anchors.top: page.top
        anchors.topMargin: Theme.paddingMedium
        anchors.right: page.right
        anchors.rightMargin: Theme.paddingLarge
        text: qsTr("Select file")
        color: Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeLarge
            family: Theme.fontFamilyHeading
        }
    }

    Label {
        id: subtitleLabel
        anchors.right: page.right
        anchors.rightMargin: Theme.paddingLarge
        anchors.left: page.left
        anchors.leftMargin: header.height - Theme.paddingLarge
        anchors.top: headerLabel.bottom
        color: Theme.secondaryColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        truncationMode: TruncationMode.Fade
        font {
            pixelSize: Theme.fontSizeExtraSmall
            family: Theme.fontFamily
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
                        pageStack.pop()
                    }
                }
            }
        }
    }

    VerticalScrollDecorator {
        flickable: listView
    }
}
