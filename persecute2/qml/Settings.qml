import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "settings"
    property variant coverNames: []

    onStatusChanged: {
        if (status === PageStatus.Inactive) {

        }
        else if (status === PageStatus.Active) {
            updatePresence()
        }
    }

    function coverActionName(index) {
        if (typeof(coverNames[index]) == "undefined") {
            coverNames = [
                        qsTr("Quit"),
                        qsTr("Change presence"),
                        qsTr("Mute/unmute"),
                        qsTr("Take picture"),
                        qsTr("Send location"),
                        qsTr("Send voice note")
                    ]
        }
        return coverNames[index]
    }

    Connections {
        target: appWindow
        onFollowPresenceChanged: updatePresence()
        onAlwaysOfflineChanged: updatePresence()
        onConnectionServerChanged: {
            connServer.currentIndex = (connectionServer == "c.whatsapp.net" ? 0
                                     :(connectionServer == "c2.whatsapp.net" ? 1
                                                                              : 2))
        }
    }

    function updatePresence() {
        presenceStatus.currentIndex = followPresence ? 0 : (alwaysOffline ? 2 : 1)
    }

    Connections {
        target: whatsapp
        onLogfileReady: {
            page.backNavigation = true
            if (isReady) {
                sendLogfile.open()
                sendLogfile.logfile = data
            }
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page

        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageStack.push(aboutPage)
                }
            }
            /*MenuItem {
                text: qsTr("Send logfile to author")
                onClicked: {
                    whatsapp.sendRecentLogs()
                    page.backNavigation = false
                }
            }*/
            MenuItem {
                text: qsTr("Account")
                onClicked: {
                    accountPage.open()
                }
            }
            MenuItem {
                text: qsTr("Muted groups")
                enabled: roster.connectionStatus == 4
                onClicked: {
                    whatsapp.getMutedGroups()
                    pageStack.push(mutedGroups)
                }
            }
            MenuItem {
                text: qsTr("Blacklist")
                enabled: roster.connectionStatus == 4
                onClicked: {
                    pageStack.push(privacyList)
                    whatsapp.getPrivacyList()
                }
            }
        }

        Column {
            id: content
            spacing: Theme.paddingSmall
            width: parent.width

            PageHeader {
                id: title
                title: qsTr("Settings")
            }

            SectionHeader {
                text: qsTr("Conversation")
            }

            ComboBox {
                label: qsTr("Conversation theme")
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem {
                        text: "Oldschool"
                    }
                    MenuItem {
                        text: "Bubbles"
                    }
                    MenuItem {
                        text: "Modern"
                    }
                    Repeater {
                        width: parent.width
                        model: conversationDelegates
                        delegate: MenuItem {
                            text: modelData
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName !== "roster") {
                        if (currentIndex == 0) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu/qml/DefaultDelegate.qml"
                        }
                        else if (currentIndex == 1) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu/qml/BubbleDelegate.qml"
                        }
                        else if (currentIndex == 2) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu/qml/ModernDelegate.qml"
                        }
                        else {
                            conversationTheme = "/home/nemo/.whatsapp/delegates/" + conversationDelegates[currentIndex - 3]
                        }
                        conversationIndex = parseInt(currentIndex)
                    }
                }
                Component.onCompleted: {
                    currentIndex = settings.value("conversationIndex", parseInt(0))
                }
            }

            TextSwitch {
                checked: notifyActive
                text: qsTr("Vibrate in active conversation")
                onClicked: notifyActive = checked
            }

            TextSwitch {
                id: timestamp
                checked: showTimestamp
                text: qsTr("Show messages timestamp")
                onClicked: showTimestamp = checked
            }

            TextSwitch {
                id: seconds
                checked: showSeconds
                text: qsTr("Show seconds in messages timestamp")
                enabled: showTimestamp
                onClicked: showSeconds = checked
            }

            TextSwitch {
                id: enter
                checked: sendByEnter
                text: qsTr("Send messages by Enter")
                onClicked: sendByEnter = checked
            }

            TextSwitch {
                checked: showKeyboard
                text: qsTr("Automatically show keyboard when opening conversation")
                onClicked: showKeyboard = checked
            }

            TextSwitch {
                checked: hideKeyboard
                text: qsTr("Hide keyboard after sending message")
                onClicked: hideKeyboard = checked
            }

            TextSwitch {
                checked: importToGallery
                text: qsTr("Download media to Gallery")
                description: qsTr("If checked downloaded files will be shown in Gallery")
                onClicked: importToGallery = checked
            }

            TextSwitch {
                checked: deleteMediaFiles
                text: qsTr("Delete media files")
                description: qsTr("Delete received media files when deleting message")
                onClicked: deleteMediaFiles = checked
            }

            Slider {
                id: fontSlider
                width: parent.width
                maximumValue: 60
                minimumValue: 8
                label: qsTr("Chat font size")
                value: fontSize
                valueText: qsTr("%1 px").arg(parseInt(value))
                onReleased: {
                    fontSize = parseInt(value)
                }
            }

            SectionHeader {
                text: qsTr("Common")
            }

            ComboBox {
                label: qsTr("Language")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: localeNames
                        delegate: MenuItem {
                            text: modelData
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName !== "roster") {
                        settings.setValue("locale", locales[currentIndex])
                        whatsapp.setLocale(locales[currentIndex])
                        banner.notify(qsTr("Restart application to change language"))
                    }
                }
                Component.onCompleted: {
                    //console.log("default: " + localeNames[localeIndex] + " locale: " + locales[localeIndex] + " index: " + localeIndex)
                    currentIndex = parseInt(localeIndex)
                }
            }

            ComboBox {
                id: connServer
                label: qsTr("Connection server") + " (*)"
                menu: ContextMenu {
                    MenuItem {
                        text: "c.whatsapp.net"
                        onClicked: {
                            connectionServer = "c.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c2.whatsapp.net"
                        onClicked: {
                            connectionServer = "c2.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c3.whatsapp.net"
                        onClicked: {
                            connectionServer = "c3.whatsapp.net"
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = (connectionServer == "c.whatsapp.net" ? 0
                                  :(connectionServer == "c2.whatsapp.net" ? 1
                                                                          : 2))
                }
            }

            TextSwitch {
                id: autostart
                checked: whatsapp.checkAutostart()
                text: qsTr("Autostart")
                onClicked: {
                    whatsapp.setAutostart(checked)
                }
            }

            TextSwitch {
                checked: keepLogs
                text: qsTr("Allow saving application logs")
                onClicked: keepLogs = checked
            }

            TextSwitch {
                checked: lockPortrait
                text: qsTr("Lock conversation orientation in portrait")
                onClicked: lockPortrait = checked
            }

            TextSwitch {
                id: showMyself
                checked: showMyJid
                text: qsTr("Show yourself in contact list, if present")
                onClicked: showMyJid = checked
            }

            TextSwitch {
                checked: acceptUnknown
                text: qsTr("Accept messages from unknown contacts")
                onClicked: acceptUnknown = checked
            }

            TextSwitch {
                checked: showConnectionNotifications
                text: qsTr("Show notifications when connection changing")
                onClicked: showConnectionNotifications = checked
            }

            Binding {
                target: muteSwitch
                property: "checked"
                value: !notificationsMuted
            }

            TextSwitch {
                id: muteSwitch
                checked: !notificationsMuted
                text: qsTr("Show new messages notifications")
                onClicked: notificationsMuted = !checked
            }

            Binding {
                target: notifySwitch
                property: "checked"
                value: notifyMessages
            }

            TextSwitch {
                id: notifySwitch
                checked: notifyMessages
                enabled: !notificationsMuted
                text: qsTr("Display messages text in notifications")
                onClicked: notifyMessages = checked
            }

            TextSwitch {
                checked: threading
                text: qsTr("Create server connection in separate thread (experimental) (*)")
                onClicked: threading = checked
            }

            SectionHeader {
                text: qsTr("Presence")
            }

            ComboBox {
                id: presenceStatus
                label: qsTr("Display presence")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("Display online when app is open")
                        onClicked: {
                            followPresence = true
                            alwaysOffline = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Always display online")
                        onClicked: {
                            alwaysOffline = false
                            followPresence = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Always display offline")
                        onClicked: {
                            alwaysOffline = true
                            followPresence = false
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = followPresence ? 0 : (alwaysOffline ? 2 : 1)
                }
            }

            SectionHeader {
                text: qsTr("Cover")
            }

            Binding {
                target: leftCoverAction
                property: "currentIndex"
                value: coverLeftAction
            }

            ComboBox {
                id: leftCoverAction
                label: qsTr("Left cover action")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: 6
                        delegate: MenuItem {
                            text: coverActionName(index)
                            onClicked: coverLeftAction = index
                        }
                    }
                }
            }

            Binding {
                target: rightCoverAction
                property: "currentIndex"
                value: coverRightAction
            }

            ComboBox {
                id: rightCoverAction
                label: qsTr("Right cover action")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: 6
                        delegate: MenuItem {
                            text: coverActionName(index)
                            onClicked: coverRightAction = index
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Media")
            }

            TextSwitch {
                checked: resizeImages
                text: qsTr("Resize sending images")
                onClicked: {
                    resizeImages = checked
                    if (!checked) {
                        sizeResize.checked = false
                        pixResize.checked = false
                    }
                }
            }

            Item {
                width: parent.width
                height: sizeSlider.height

                TextSwitch {
                    id: sizeResize
                    text: ""
                    width: Theme.itemSizeSmall
                    enabled: resizeImages
                    checked: resizeImages && resizeBySize
                    onClicked: {
                        resizeBySize = checked
                        pixResize.checked = !checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }


                Slider {
                    id: sizeSlider
                    enabled: resizeBySize
                    anchors.left: sizeResize.right
                    anchors.right: parent.right
                    maximumValue: 5242880
                    minimumValue: 204800
                    label: qsTr("Maximum image size by file size")
                    value: resizeImagesTo
                    valueText: bytesToSize(parseInt(value))
                    onReleased: {
                        resizeImagesTo = parseInt(value)
                    }
                }
            }

            Item {
                width: parent.width
                height: pixSlider.height

                TextSwitch {
                    id: pixResize
                    text: ""
                    width: Theme.itemSizeSmall
                    enabled: resizeImages
                    checked: resizeImages && !resizeBySize
                    onClicked: {
                        resizeBySize = !checked
                        sizeResize.checked = !checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    id: pixSlider
                    enabled: !resizeBySize
                    anchors.left: pixResize.right
                    anchors.right: parent.right
                    maximumValue: 9.0
                    minimumValue: 0.2
                    label: qsTr("Maximum image size by resolution")
                    value: resizeImagesToMPix
                    valueText: qsTr("%1 MPx").arg(parseFloat(value.toPrecision(2)))
                    onReleased: {
                        resizeImagesToMPix = parseFloat(value.toPrecision(2))
                    }
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                wrapMode: Text.Wrap
                text: qsTr("Options marked with (*) will take effect after reconnection")
            }
        }
    }

    VerticalScrollDecorator {
        flickable: flick
    }

    Dialog {
        id: sendLogfile
        canAccept: (email.text.length > 0) && (comment.text.length > 0)
        onAccepted: {
            email.deselect()
            comment.deselect()
            Utilities.submitDebugInfo(comment, email, logfile, function(status, result) {
                console.log("sent result: " + status + " message: " + result);
            })
        }

        property variant logfile

        SilicaFlickable {
            id: flicka
            anchors.fill: parent

            Column {
                width: parent.width
                spacing: Theme.paddingLarge

                DialogHeader {
                    title: qsTr("Send logs")
                }

                TextField {
                    id: email
                    placeholderText: "youremail@domain.com"
                    label: qsTr("Your email address")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.paddingLarge
                    inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                }

                TextArea {
                    id: comment
                    placeholderText: qsTr("Enter bug description here. As many information as  possible.")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.paddingLarge
                    background: null
                    height: 400
                }
            }
        }
    }
}
