import QtQuick 2.0
import com.jolla.gallery 1.0
import harbour.mitakuuluu.filemodel 1.0

MediaSource {
    id: root

    //: Label of the Mitakuuluu album in Jolla Gallery application
    //% "Mitakuuluu"
    title: qsTrId("Mitakuuluu")
    icon: "/usr/share/harbour-mitakuuluu/mediasource/GalleryIcon.qml"
    page: "/usr/share/harbour-mitakuuluu/mediasource/GalleryGridPage.qml"
    model: _fm
    count: _fm.count
    ready: count > 0

    property Filemodel _fm: Filemodel {
    	sorting: true
    	filter: ["*.*"]
    	rpath: "/home/nemo/WhatsApp"
        onCountChanged: {
            root.count = _fm.count
        }
    }
}
