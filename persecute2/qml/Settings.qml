import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "settings"

    onStatusChanged: {
        if (status === PageStatus.Inactive) {

        }
        else if (status === PageStatus.Active) {

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
                    whatsapp.sendRecentLogs() //disabled until mailto attach not working
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
                    whatsapp.getPrivacyList()
                    pageStack.push(privacyList)
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
                        text: "Mitakuuluu"
                        onClicked: {
                            console.log("default delegate selected")
                            conversationTheme = "/usr/share/harbour-mitakuuluu/qml/DefaultDelegate.qml"
                            settings.setValue("conversationTheme", conversationTheme)
                            settings.setValue("conversationIndex", parseInt(0))
                        }
                    }
                    Repeater {
                        width: parent.width
                        model: conversationDelegates
                        delegate: MenuItem {
                            text: modelData
                            onClicked: {
                                console.log("selected " + modelData + " delegate")
                                conversationTheme = "/home/nemo/.whatsapp/delegates/" + modelData
                                settings.setValue("conversationTheme", conversationTheme)
                                settings.setValue("conversationIndex", parseInt(index + 1))
                            }
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = settings.value("conversationIndex", parseInt(0))
                }
            }

            /*TextSwitch {
                checked: asynchronousDelegate
                text: qsTr("Load delegates asynchronously")
                onClicked: {
                    asynchronousDelegate = checked
                    settings.setValue("asynchronousDelegate", checked)
                }
            }*/

            TextSwitch {
                checked: notifyActive
                text: qsTr("Vibrate in active conversation")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        notifyActive = checked
                        settings.setValue("notifyActive", checked)
                    }
                }
            }

            TextSwitch {
                id: timestamp
                checked: showTimestamp
                text: qsTr("Show messages timestamp")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        showTimestamp = checked
                        settings.setValue("showTimestamp", checked)
                    }
                }
            }

            TextSwitch {
                id: seconds
                checked: showSeconds
                text: qsTr("Show seconds in messages timestamp")
                enabled: showTimestamp
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        showSeconds = checked
                        settings.setValue("showSeconds", checked)
                    }
                }
            }

            TextSwitch {
                id: enter
                checked: sendByEnter
                text: qsTr("Send messages by Enter")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        sendByEnter = checked
                        settings.setValue("sendByEnter", checked)
                    }
                }
            }

            TextSwitch {
                checked: showKeyboard
                text: qsTr("Show keyboard automatically")
                description: qsTr("Automatically show keyboard when opening conversation")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        showKeyboard = checked
                        settings.setValue("showKeyboard", checked)
                    }
                }
            }

            TextSwitch {
                checked: deleteMediaFiles
                text: qsTr("Delete media files")
                description: qsTr("Delete received media files when deleting message")
                onClicked: {
                    deleteMediaFiles = checked
                    settings.setValue("deleteMediaFiles", checked)
                }
            }

            Slider {
                id: fontSlider
                width: parent.width
                maximumValue: 60
                minimumValue: 8
                label: qsTr("Chat font size")
                value: fontSize
                valueText: qsTr("%1 px").arg(parseInt(value))
                onValueChanged: {
                    if (page.status == PageStatus.Active) {
                        fontSize = parseInt(value)
                        settings.setValue("fontSize", fontSize)
                    }
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
                        //console.log(" index: " + currentIndex)
                        //console.log("selected: " + localeNames[currentIndex] + " locale: " + locales[currentIndex] + " index: " + currentIndex)
                        settings.setValue("locale", locales[currentIndex])
                        whatsapp.setLocale(locales[currentIndex])
                        banner.notify(qsTr("Restart application to change language"))
                        //pageStack.clear()
                        //pageStack.push(roster)
                    }
                }
                Component.onCompleted: {
                    //console.log("default: " + localeNames[localeIndex] + " locale: " + locales[localeIndex] + " index: " + localeIndex)
                    currentIndex = parseInt(localeIndex)
                }
            }

            TextSwitch {
                id: showMyself
                checked: showMyJid
                text: qsTr("Show yourself in contact list, if present")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        showMyJid = checked
                        settings.setValue("showMyJid", checked)
                    }
                }
            }

            TextSwitch {
                checked: acceptUnknown
                text: qsTr("Accept messages from unknown contacts")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        acceptUnknown = checked
                        settings.setValue("acceptUnknown", checked)
                    }
                }
            }

            /*TextSwitch {
                checked: softbankReplacer
                text: "Display all emoji"
                description: "Try to display all emoji. Can take extra time to open conversations with emoji"
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        softbankReplacer = checked
                        settings.setValue("softbankReplacer", checked)
                    }
                }
            }*/

            TextSwitch {
                id: presence
                checked: followPresence
                text: qsTr("Set unavailable when window closed or minimized")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        followPresence = checked
                        settings.setValue("followPresence", checked)
                    }
                }
            }

            Item {
                height: onlineSwitch.height
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !followPresence

                Switch {
                    id: onlineSwitch
                    anchors.left: parent.left
                    checked: !alwaysOffline
                    enabled: !followPresence
                    onClicked: {
                        offlineSwitch.checked = !checked
                        settings.setValue("alwaysOffline", !checked)
                        alwaysOffline = !checked
                        if (checked)
                            whatsapp.setPresenceAvailable()
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: onlineSwitch.verticalCenter
                    text: alwaysOffline ? qsTr("Always offline") : qsTr("Always online")
                    enabled: !followPresence

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (onlineSwitch.checked)
                                offlineSwitch.clicked(mouse)
                            else
                                onlineSwitch.clicked(mouse)
                        }
                    }
                }

                Switch {
                    id: offlineSwitch
                    anchors.right: parent.right
                    checked: alwaysOffline
                    enabled: !followPresence
                    onClicked: {
                        onlineSwitch.checked = !checked
                        settings.setValue("alwaysOffline", checked)
                        alwaysOffline = checked
                        if (checked)
                            whatsapp.setPresenceUnavailable()
                    }
                }
            }
            SectionHeader {
                text: qsTr("Media")
            }

            TextSwitch {
                checked: resizeImages
                text: qsTr("Resize sending images")
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        resizeImages = checked
                        settings.setValue("resizeImages", checked)
                        if (!checked) {
                            sizeResize.checked = false
                            pixResize.checked = false
                        }
                    }
                }
            }

            TextSwitch {
                id: sizeResize
                text: ""
                width: parent.width
                enabled: resizeImages
                checked: resizeImages && resizeBySize
                onClicked: {
                    resizeBySize = checked
                    settings.setValue("resizeBySize", checked)
                    pixResize.checked = !checked
                }

                Slider {
                    enabled: resizeBySize
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    maximumValue: 5242880
                    minimumValue: 204800
                    label: qsTr("Maximum image size by file size")
                    value: resizeImagesTo
                    valueText: bytesToSize(parseInt(value))
                    onValueChanged: {
                        if (page.status == PageStatus.Active) {
                            resizeImagesTo = parseInt(value)
                            settings.setValue("resizeImagesTo", resizeImagesTo)
                        }
                    }
                }
            }

            TextSwitch {
                id: pixResize
                text: ""
                width: parent.width
                enabled: resizeImages
                checked: resizeImages && !resizeBySize
                onClicked: {
                    resizeBySize = !checked
                    settings.setValue("resizeBySize", !checked)
                    sizeResize.checked = !checked
                }

                Slider {
                    enabled: !resizeBySize
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    maximumValue: 9.0
                    minimumValue: 0.2
                    label: qsTr("Maximum image size by resolution")
                    value: resizeImagesToMPix
                    valueText: qsTr("%1 MPx").arg(parseFloat(value.toPrecision(2)))
                    onValueChanged: {
                        if (page.status == PageStatus.Active) {
                            resizeImagesToMPix = parseFloat(value.toPrecision(2))
                            settings.setValue("resizeImagesToMPix", resizeImagesToMPix)
                        }
                    }
                }
            }
        }
    }

    VerticalScrollDecorator {
        flickable: flick
    }
}
