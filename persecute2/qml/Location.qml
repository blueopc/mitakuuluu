import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import "Utilities.js" as Utilities
import QtLocation 5.0
import QtPositioning 5.0
import org.nemomobile.configuration 1.0

Dialog {
	id: page
    objectName: "location"
    allowedOrientations: Orientation.Portrait

    property bool broadcastMode: true
    property PositionSource positionSource

    canAccept: false

    onAccepted: {
        console.log("accepting lat: " + latitude + " lon: " + longitude)
        if (broadcastMode) {
            pageStack.pop(roster, PageStackAction.Immediate)
            roster.sendLocation(latitude, longitude, zoom, googlemaps)
        }
        else {
            pageStack.pop(conversation, PageStackAction.Immediate)
            conversation.sendLocation(latitude, longitude, zoom, googlemaps)
        }
    }

    property real latitude: 55.159479
    property real longitude: 61.402796
    property int zoom: 16
    property bool googlemaps: false

    onStatusChanged: {
        if (status == PageStatus.Inactive && locationEnabledConfig.value) {
            console.log("deactivating positionSource")
            positionSource.destroy()
            positionSource = null
        }
        else if (status == PageStatus.Active && locationEnabledConfig.value) {
            console.log("activating positionSource")
            createPositionSource()
        }
    }

    ConfigurationValue {
        id: locationEnabledConfig
        key: "/jolla/location/enabled"
        defaultValue: false
    }

    function createPositionSource() {
        positionSource = positionSourceComponent.createObject(null)
    }

    Timer {
        id: positionSourceRecreationTimer
        interval: 1500
        onTriggered: {
            createPositionSource()
        }
    }

    Component {
        id: positionSourceComponent
        PositionSource {
            active: true
            updateInterval : 1000

            onPositionChanged: {
                if (positionSource
                        && positionSource.position
                        && positionSource.position.longitudeValid
                        && positionSource.position.latitudeValid) {
                    page.canAccept = true
                    page.latitude = positionSource.position.coordinate.latitude
                    page.longitude = positionSource.position.coordinate.longitude
                }
                else
                    page.canAccept = false
                if (locationImg.status != Image.Ready)
                    locationImg.loadImage()
            }

            Component.onCompleted: {
            }

            onSourceErrorChanged: {
                if (sourceError === PositionSource.ClosedError) {
                    console.log("Position source backend closed, restarting...")
                    positionSourceRecreationTimer.restart()
                    positionSource.destroy()
                }
            }
        }
    }

    DialogHeader {
        id: header
        //title: qsTr("Location")
    }

    Label {
        visible: !locationEnabledConfig.value
        text: "You need to enable GPS positioning in settings"
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Image {
        id: locationImg
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: page.bottom
        }
        visible: locationEnabledConfig.value && status == Image.Ready
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectFit
        verticalAlignment: Image.AlignTop

        function loadImage() {
            if (positionSource
                    && positionSource.position
                    && positionSource.position.longitudeValid
                    && positionSource.position.latitudeValid) {
                if (googlemaps) {
                    locationImg.source = "http://maps.googleapis.com/maps/api/staticmap?zoom=" + page.zoom
                            + "&size="
                            + locationImg.width
                            + "x" + locationImg.height
                            +"&maptype=roadmap&sensor=false&markers=color:red|label:.|"
                            + page.latitude
                            + ","
                            + page.longitude
                }
                else {
                    locationImg.source = "http://m.nok.it/?ctr="
                            + page.latitude
                            + ","
                            + page.longitude
                            + "&w=" + locationImg.width
                            + "&h=" + locationImg.height
                            + "&poix0="
                            + page.latitude
                            + ","
                            + page.longitude
                            + ";red;white;20;.;"
                            + "&z=" + page.zoom
                            + "&nord&f=0&poithm=1&poilbl=0"
                }
                console.log("loading: " + locationImg.source)
            }
        }
    }

    /*Rectangle {
        anchors.fill: dataColumn
        anchors.margins: -Theme.paddingLarge
        color: Theme.rgba(Theme.highlightColor, 0.8)
    }*/

    Column {
        id: dataColumn
        visible: locationEnabledConfig.value
        anchors.left: locationImg.left
        anchors.leftMargin: Theme.paddingLarge
        anchors.bottom: locationImg.bottom
        anchors.bottomMargin: Theme.paddingLarge
        Label {
            x: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeMedium
            style: Text.Outline
            styleColor: Theme.secondaryHighlightColor
            text: qsTr("latitude: %1").arg(page.latitude)
        }
        Label {
            x: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeMedium
            style: Text.Outline
            styleColor: Theme.secondaryHighlightColor
            text: qsTr("longitude: %1").arg(page.longitude)
        }
        /*Label {
            x: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeMedium
            style: Text.Outline
            styleColor: Theme.highlightColor
            text: qsTr("longitudeValid: %1").arg(positionSource.position.longitudeValid)
        }
        Label {
            x: Theme.paddingLarge
            color: "white"
            font.pixelSize: Theme.fontSizeMedium
            style: Text.Outline
            styleColor: Theme.highlightColor
            text: qsTr("latitudeValid: %1").arg(positionSource.position.latitudeValid)
        }*/
    }

    /*Button {
        id: acceptBtn
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("Send")
        enabled: page.canAccept
        onClicked: {
            console.log("accepting lon: " + longitude + " lat: " + latitude)
        }
    }*/

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: visible
        visible: locationImg.status != Image.Ready
    }

    Rectangle {
        id: bt1
        anchors.top: header.bottom
        anchors.right: parent.right
        anchors.margins: Theme.paddingMedium
        width: 64
        height: 64
        radius: width / 2
        color: ib1.pressed ? "#20808080" : "#40808080"
        IconButton {
            id: ib1
            anchors.centerIn: parent
            icon.source: "image://theme/icon-m-refresh"
            icon.width: 48
            icon.height: 48
            highlighted: pressed
            onClicked: {
                locationImg.loadImage()
            }
        }
    }

    Rectangle {
        id: bt2
        anchors.top: bt1.bottom
        anchors.right: parent.right
        anchors.margins: Theme.paddingMedium
        width: 64
        height: 64
        radius: width / 2
        color: ib2.pressed ? "#20808080" : "#40808080"
        IconButton {
            id: ib2
            anchors.centerIn: parent
            icon.source: "image://theme/icon-camera-zoom-tele"
            icon.width: 48
            icon.height: 48
            highlighted: pressed
            onClicked: {
                if (zoom < 18)
                    zoom++
                locationImg.loadImage()

            }
        }
    }

    Rectangle {
        id: bt3
        anchors.top: bt2.bottom
        anchors.right: parent.right
        anchors.margins: Theme.paddingMedium
        width: 64
        height: 64
        radius: width / 2
        color: ib3.pressed ? "#20808080" : "#40808080"
        IconButton {
            id: ib3
            anchors.centerIn: parent
            icon.source: "image://theme/icon-camera-zoom-wide"
            icon.width: 48
            icon.height: 48
            highlighted: pressed
            onClicked: {
                if (zoom > 0)
                    zoom--
                locationImg.loadImage()
            }
        }
    }

    IconButton {
        id: bt4
        width: 64
        height: 64
        anchors.top: bt3.bottom
        anchors.right: parent.right
        anchors.margins: Theme.paddingMedium
        icon.source: googlemaps ? "../images/googlemaps.png" : "../images/heremaps.png"
        highlighted: pressed
        onClicked: {
            googlemaps = !googlemaps
            locationImg.loadImage()

        }
    }
} 
