import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "settings"
    allowedOrientations: Orientation.Portrait

    onStatusChanged: {
        if (status === PageStatus.Inactive) {

        }
        else if (status === PageStatus.Active) {

        }
    }

    PageHeader {
        id: title
        title: "Settings"
    }

    SilicaFlickable {
        id: flick
        anchors.top: title.bottom
        anchors.bottom: page.bottom
        anchors.left: page.left
        anchors.right: page.right
        clip: true

        contentHeight: content.height

        Column {
            id: content
            spacing: Theme.paddingSmall
            width: parent.width

            TextSwitch {
                checked: acceptUnknown
                text: "Accept messages from unknown contacts"
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        acceptUnknown = checked
                        settings.setValue("acceptUnknown", checked)
                    }
                }
            }

            TextSwitch {
                checked: notifyActive
                text: "Vibrate in active conversation"
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
                text: "Show messages timestamp"
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
                text: "Show seconds in messages timestamp"
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
                text: "Send messages by Enter"
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        sendByEnter = checked
                        settings.setValue("sendByEnter", checked)
                    }
                }
            }

            TextSwitch {
                checked: showKeyboard
                text: "Show keyboard automatically"
                description: "Automatically show keyboard when opening conversation"
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        showKeyboard = checked
                        settings.setValue("showKeyboard", checked)
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
                text: "Set unavailable when window closed or minimized"
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        followPresence = checked
                        settings.setValue("followPresence", checked)
                    }
                }
            }

            TextSwitch {
                id: showMyself
                checked: showMyJid
                text: "Show yourself in contact list, if present"
                onCheckedChanged: {
                    if (page.status == PageStatus.Active) {
                        showMyJid = checked
                        settings.setValue("showMyJid", checked)
                    }
                }
            }

            Slider {
                id: fontSlider
                width: parent.width
                maximumValue: 60
                minimumValue: 8
                label: "Chat font size"
                value: fontSize
                valueText: parseInt(value) + "px"
                onValueChanged: {
                    if (page.status == PageStatus.Active) {
                        settings.setValue("fontSize", parseInt(fontSlider.value))
                    }
                }
            }

            Button {
                text: "Blacklist"
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: roster.connectionStatus == 4
                onClicked: {
                    whatsapp.getPrivacyList()
                    pageStack.push(privacyList)
                }
            }

            Button {
                text: "Muted groups"
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: roster.connectionStatus == 4
                onClicked: {
                    whatsapp.getMutedGroups()
                    pageStack.push(mutedGroups)
                }
            }

            Button {
                text: "Account"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    accountPage.open()
                }
            }

            Button {
                text: "About"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    pageStack.push(aboutPage)
                }
            }
        }
    }

    VerticalScrollDecorator {
        flickable: flick
    }
}
