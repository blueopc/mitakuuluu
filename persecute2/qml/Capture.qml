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
                resolution: "3264x2448"

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
    	id: shutter
    	source: "image://theme/icon-camera-shutter-release"
    	anchors.left: parent.left
    	anchors.bottom: parent.bottom
    	anchors.margins: Theme.paddingLarge
    	property bool autoMode: false

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
            	pageStack.pop(conversation, PageStackAction.Immediate)
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
