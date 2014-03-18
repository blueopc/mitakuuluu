import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: detailsPage
    property variant modelItem

    onStatusChanged: {
        if (status == PageStatus.Activating) {
            nameItem.value = modelItem.path
            sizeItem.value = Format.formatFileSize(modelItem.size)
            widthItem.value = modelItem.width
            heightItem.value = modelItem.height
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        PageHeader {
            //% "Details"
            title: qsTrId("components_gallery-he-details")
        }
        GalleryDetailsItem {
            id: nameItem
            //% "Filename"
            detail: qsTrId("components_gallery-la-filename")
        }
        GalleryDetailsItem {
            id: sizeItem
            //% "Size"
            detail: qsTrId("components_gallery-la-size")
        }
        GalleryDetailsItem {
            id: widthItem
            //% "Width"
            detail: qsTrId("components_gallery-la-width")
        }
        GalleryDetailsItem {
            id: heightItem
            //% "Height"
            detail: qsTrId("components_gallery-la-height")
        }
    }
}
