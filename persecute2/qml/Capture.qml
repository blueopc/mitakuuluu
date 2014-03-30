import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import "Utilities.js" as Utilities
import QtMultimedia 5.0
import Sailfish.Media 1.0

Page {
	id: page
	objectName: "capture"
    allowedOrientations: Orientation.Portrait

    onStatusChanged: {
    	if (status == PageStatus.Inactive) {
    		console.log("deactivating camera")
    		camera.cameraState = Camera.UnloadedState
    	}
    	else if (status == PageStatus.Active) {
    		console.log("activating camera")
    		camera.cameraState = Camera.ActiveState
    	}
    }

    Component.onDestruction: {
        console.log("camera destruction")
        camera.cameraState = Camera.UnloadedState
    }

    property bool broadcastMode: true

    PageHeader {
    	title: qsTr("Make photo")
    }

	GStreamerVideoOutput {
        id:mPreview
        x:0
        y:0
        anchors.fill: parent
        orientation: 0

        source: Camera {
            id: camera

            // Set this to Camera.ActiveState to load, and Camera.UnloadedState to unload.
            //cameraState: Camera.ActiveState

            // Options are Camera.CaptureStillImage or Camera.CaptureVideo
            captureMode: Camera.CaptureStillImage

            focus.focusMode: Camera.FocusAuto
            flash.mode: Camera.FlashOn

            imageCapture {
                resolution: "1280x720"

                onImageCaptured:{
                }

                // Called when the image is saved.
                onImageSaved: {
                    console.log("Photo saved to", path)
                    imagePreview.image = path
                    imagePreview.open()
                }

                // Called when a capture fails for some reason.
                onCaptureFailed: {
                    console.log("Capture failed")
                }

            }

            // This will tell us when focus lock is gained.
            onLockStatusChanged: {
                if (lockStatus == Camera.Locked) {
                    console.log("locked")
                    if (shutter.autoMode)
                    	camera.imageCapture.capture()
                }
            }
        }
    }

    Image {
        id: flashMode
        source: flashModeIcon(camera.flash.mode)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.paddingLarge
        property bool flash: true
        rotation: 90

        function flashModeIcon(mode) {
            switch (mode) {
            case Camera.FlashAuto:
                return "image://theme/icon-camera-flash-automatic"
            case Camera.FlashOff:
                return "image://theme/icon-camera-flash-off"
            case Camera.FlashRedEyeReduction:
                return "image://theme/icon-camera-flash-redeye"
            default:
                return "image://theme/icon-camera-flash-on"
            }
        }

        function nextFlashMode(mode) {
            switch (mode) {
            case Camera.FlashAuto:
                return Camera.FlashRedEyeReduction
            case Camera.FlashOff:
                return Camera.FlashOn
            case Camera.FlashRedEyeReduction:
                return Camera.FlashOff
            default:
                return Camera.FlashAuto
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: camera.flash.mode = flashMode.nextFlashMode(camera.flash.mode)
        }
    }

    Image {
    	id: shutter
    	source: "image://theme/icon-camera-shutter-release"
    	anchors.left: parent.left
    	anchors.bottom: parent.bottom
    	anchors.margins: Theme.paddingLarge
    	property bool autoMode: false
        rotation: 90

        MouseArea {
            anchors.fill: parent
            onPressed: {
            	console.log("shutter pressed")
            	shutter.autoMode = false
            	camera.searchAndLock()
            }
            onReleased: {
            	console.log("shutter released")
            	shutter.autoMode = false
            	if (camera.lockStatus == Camera.Locked) { 
                    camera.imageCapture.capture()
                }
            }
            /*onClicked: {
            	console.log("shutter clicked")
            	shutter.autoMode = true
            	camera.searchAndLock()
            }*/
        }
    }

    Dialog {
    	id: imagePreview
    	onAccepted: {
            if (broadcastMode) {
            	pageStack.pop(roster, PageStackAction.Immediate)
            	roster.sendImage(image)
            }
            else {
                pageStack.pop(page, PageStackAction.Immediate)
            	conversation.sendMedia(image)
            }
    	}
    	property string image: ""

    	DialogHeader {}

	    Image {
	    	id: prev
	    	anchors.fill: parent
	    	visible: status == Image.Ready
	    	fillMode: Image.PreserveAspectFit
	    	asynchronous: true
	    	source: imagePreview.image
	    }
    }
} 
