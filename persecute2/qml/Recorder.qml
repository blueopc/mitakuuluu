import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import QtMultimedia 5.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    objectName: "recorder"

    canAccept: false

    property bool broadcastMode: false
    property AudioRecorder recorder
    property Audio player

    onAccepted: {
        console.log("accepting: " + recorder.path)
        if (broadcastMode) {
            pageStack.pop(roster, PageStackAction.Immediate)
            //roster.sendAudioNote(recorder.path)
        }
        else {
            pageStack.pop(conversation, PageStackAction.Immediate)
            //conversation.sendAudioNote(recorder.path)
        }
        destroyComponents()
    }

    onRejected: {
        destroyComponents()
    }

    function destroyComponents() {
        if (recorder) {
            recorder.destroy()
            recorder = null
        }
        if (player) {
            player.destroy()
            player = null
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
        }
        else if (status == PageStatus.Active) {
            recorder = recorderComponent.createObject(null)
            player = playerComponent.createObject(null)
        }
    }

    Component {
        id: recorderComponent
        AudioRecorder {
            /*onPathChanged: {
                console.log("recorder new path: " + path)
            }
            onStatusChanged: {
                console.log("recorder status: " + status)
            }*/
            onStateChanged: {
                //console.log("recorder state: " + state)
                if (state == AudioRecorder.StoppedState) {
                    page.canAccept = player.playbackState == Audio.StoppedState
                    player.source = recorder.path
                }
            }
            /*onErrorOccured: {
                console.log("recorder error: " + error)
            }
            onAvailabilityChanged: {
                console.log("recorder availability: " + availability)
            }*/
            onDurationChanged: {
                //console.log("recorder duration: " + duration)
                progress.value = duration
                progress.label = Format.formatDuration(duration / 1000, Format.DurationShort)
            }
            /*Component.onCompleted: {
                console.log("location: " + recorder.path)
            }*/
        }
    }

    Component {
        id: playerComponent
        Audio {
            onPlaybackStateChanged: {
                page.canAccept = player.playbackState == Audio.StoppedState && recorder.state == AudioRecorder.StoppedState
            }
            onPositionChanged: {
                //console.log("playback position: " + position)
                progress.value = position
                progress.label = Format.formatDuration(position / 1000, Format.DurationShort)
            }
            onDurationChanged: {
                //console.log("playback duration: " + duration)
                progress.maximumValue = duration
            }
            /*onSourceChanged: {
                console.log("playback source: " + source)
            }
            onFilesizeChanged: {
                console.log("playback filesize: " + filesize)
            }*/
        }
    }

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            margins: Theme.paddingLarge
        }

        DialogHeader {
            title: qsTr("Voice note")
        }

        ProgressBar {
            id: progress
            width: parent.width
            minimumValue: 0
            maximumValue: 1
            //label: qsTr("Duration")

            Label {
                id: minLabel
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    bottom: parent.bottom
                }
                text: Format.formatDuration(progress.minimumValue / 1000, Format.DurationShort)
            }

            Label {
                id: maxLabel
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                    bottom: parent.bottom
                }
                text: Format.formatDuration(progress.maximumValue / 1000, Format.DurationShort)
            }
        }

        SectionHeader {
            text: qsTr("Recorder")
        }

        Row {
            width: parent.width
            spacing: Theme.paddingLarge

            Button {
                text: recorder.state == AudioRecorder.RecordingState ? qsTr("Pause") : qsTr("Record")
                enabled: player.playbackState != Audio.PlayingState
                onClicked: {
                    if (recorder.state == AudioRecorder.RecordingState) {
                        progress.indeterminate = false
                        recorder.pause()
                    }
                    else {
                        progress.maximumValue = 120000
                        progress.indeterminate = true
                        recorder.record()
                    }
                }
            }

            Button {
                text: qsTr("Stop")
                enabled: recorder.state != AudioRecorder.StoppedState
                onClicked: {
                    progress.indeterminate = false
                    recorder.stop()
                }
            }
        }

        SectionHeader {
            text: qsTr("Playback")
        }

        Row {
            width: parent.width
            spacing: Theme.paddingLarge

            Button {
                text: player.playbackState == Audio.PlayingState ? qsTr("Pause") : qsTr("Play")
                enabled: recorder.state == AudioRecorder.StoppedState
                onClicked: {
                    if (player.playbackState == Audio.PlayingState) {
                        player.pause()
                    }
                    else {
                        progress.indeterminate = false
                        player.source = recorder.path
                        //player.seek(0)
                        progress.maximumValue = player.duration
                        progress.value = 0
                        player.play()
                    }
                }
            }

            Button {
                text: qsTr("Stop")
                enabled: player.playbackState != Audio.StoppedState
                onClicked: {
                    player.stop()
                }
            }
        }
    }
}
