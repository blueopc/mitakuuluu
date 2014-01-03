import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "roster"
    allowedOrientations: Orientation.Portrait

    property int connectionStatus: 0
    property bool networkAvailable: false
    property string myJid: ""
    property string pendingGroup: ""

    property alias contacts: contactsModel

    property int unreadCount: 0

    property bool inStack: true

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            var haveRoster = pageStack.find( function(xpage) {
                return (xpage.objectName == "roster")
            })
            inStack = (haveRoster && haveRoster.objectName == "roster")
        }
    }

    Connections {
        target: contactsModel
        onTotalUnreadChanged: {
            page.unreadCount = contactsModel.totalUnread
        }
    }

    Component.onCompleted: {
        myJid = whatsapp.getMyAccount()
        connectionStatus = whatsapp.connectionStatus()
        networkAvailable = whatsapp.networkAvailable
        contactsModel.contactsChanged()
    }

    Connections {
        target: whatsapp
        onConnectionStatusChanged: {
            connectionStatus = connStatus
            myJid = whatsapp.getMyAccount()
        }
        onNetworkChanged: {
            networkAvailable = value
        }
        onGroupCreated: {
            pendingGroup = gjid
        }
        onContactChanged: {
            if (data.jid == pendingGroup) {
                pendingGroup = ""
                pageStack.push(groupPage)
                groupPage.loadContact(data)
            }
        }
        onNotificationOpenJid: {
            console.log("notification pressed for: " + njid)
            appWindow.activate()
            pageStack.pop(roster, PageStackAction.Immediate)
            conversation.loadContactModel(contactsModel.getModel(njid))
            pageStack.push(conversation, {}, PageStackAction.Immediate)
        }
        onSynchronizationFinished: {
            banner.notify(qsTr("Contacts syncing finished!"))
        }
        onSynchronizationFailed: {
            banner.notify(qsTr("Contacts syncing failed!"), "#A0FF4000")
        }
        onUploadMediaFailed: {
            banner.notify(qsTr("Media uploading failed!"), "#A0FF2020")
        }
    }

    function parseConnectionStatus(value) {
        var array = [qsTr("Unknown"),
                     qsTr("Waiting for connection"),
                     qsTr("Connecting..."),
                     qsTr("Connected"),
                     qsTr("Logged in"),
                     qsTr("Login failure!"),
                     qsTr("Disconnected"),
                     qsTr("Registering..."),
                     qsTr("Registration failed!")]
        return array[value]
    }

    function parseConnectionColor(value) {
        var array = [Theme.primaryColor,
                     Theme.primaryColor,
                     Theme.primaryColor,
                     Theme.primaryColor,
                     Theme.highlightColor,
                     "red",
                     Theme.primaryColor,
                     Theme.primaryColor,
                     "red"]
        return array[value]
    }

    function parseConnectionAction(value) {
        var array = [qsTr("No action"),
                     qsTr("Force connect"),
                     qsTr("Disconnect"),
                     qsTr("Disconnect"),
                     qsTr("Disconnect"),
                     qsTr("Register"),
                     qsTr("Connect"),
                     qsTr("No action"),
                     qsTr("Register")]
        return array[value]
    }

    function getContactColor(jid) {
        return contactsModel.getColorForJid(jid)
    }

    function getNicknameByJid(jid) {
        if (jid == myJid)
            return qsTr("You")
        var model = contactsModel.getModel(jid)
        if (model && model.nickname)
            return model.nickname
        else
            return jid.split("@")[0]
    }

    function getContactModel(jid) {
        return contactsModel.getModel(jid)
    }

    function reloadContact(jid) {
        contactsModel.reloadContact(jid)
    }

    function deleteEverything() {
        contactsModel.deleteEverything()
    }

    SilicaFlickable {
        anchors.fill: parent
        clip: true
        interactive: !listView.flicking
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                id: shutdown
                text: qsTr("Quit")
                font.bold: true
                //color: enabled ? (down || highlighted ? "#FF0000" : "#E0FF2020") : "#C00000"
                onClicked: {
                    remorseDisconnect.execute(qsTr("Quit and shutdown engine"),
                                               function() {
                                                   whatsapp.shutdown()
                                                   Qt.quit()
                                               },
                                               5000)
                }
            }

            MenuItem {
                id: goSettings
                text: qsTr("Settings")
                onClicked: {
                    pageStack.push(settingsPage)
                }
            }

            MenuItem {
                id: createGroup
                text: qsTr("New group")
                enabled: connectionStatus == 4
                onClicked: {
                    newGroup.open()
                }
            }

            MenuItem {
                id: broadcastMessage
                text: qsTr("Broadcast")
                enabled: connectionStatus == 4
                onClicked: {
                    broadcast.open()
                }
            }

            MenuItem {
                text: qsTr("Add contacts")
                enabled: connectionStatus == 4
                onClicked: {
                    //whatsapp.syncContactList()
                    selectPhonebook.open()
                }
            }

            MenuItem {
                id: connectDisconnect
                enabled: connectionStatus > 0
                text: parseConnectionAction(connectionStatus)
                onClicked: {
                    if (connectionStatus == 1) {
                        whatsapp.forceConnection()
                    }
                    else if (connectionStatus > 1 && connectionStatus < 5) {
                        remorseDisconnect.execute(qsTr("Disconnecting"),
                                                   function() {
                                                       whatsapp.disconnect()
                                                   },
                                                   5000)
                    }
                    else if (connectionStatus == 6)
                        whatsapp.authenticate()
                    else
                        pageStack.replace(register)
                }
            }

            /*MenuItem {
                id: sendLogs
                visible: applicationCrashed
                text: "Send logs"
                onClicked: {
                    settings.setValue("selfkill", true)
                    applicationCrashed = false
                    whatsapp.sendRecentLogs()
                }
            }*/
        }

        PageHeader {
            id: header
            title: parseConnectionStatus(connectionStatus)
            _titleItem.color: parseConnectionColor(connectionStatus)

            IconButton {
                id: searchContact
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                icon.source: "image://theme/icon-m-search"
                highlighted: searchArea.visible
                onClicked: {
                    searchField.text = ""
                    searchIndicator.visible = false
                    searchArea.visible = !searchArea.visible
                    contactsModel.filtering = searchArea.visible
                    contactsModel.filter = ""
                    fastScroll.init()
                }

                BusyIndicator {
                    id: searchIndicator
                    anchors.top: parent.top
                    anchors.topMargin: 13
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    size: BusyIndicatorSize.Medium
                    smooth: true
                    width: 37
                    height: 37
                    running: visible
                    visible: false
                }
            }

            /*Label {
                id: headerText
                width: Math.min(implicitWidth, parent.width - Theme.paddingLarge)
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                }
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
                text: "Mitakuuluu"
            }*/
        }

        Item {
            id: searchArea
            anchors.top: header.bottom
            width: page.width
            height: 60
            visible: false

            TextArea {
                id: searchField
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                placeholderText: qsTr("Enter contact name to search")
                inputMethodHints: Qt.ImhNoPredictiveText
                onTextChanged: {
                    if (activeFocus) {
                        searchIndicator.visible = true
                        searchTimer.restart()
                    }
                }
            }

            Timer {
                id: searchTimer
                interval: 500
                repeat: false
                onTriggered: {
                    searchIndicator.visible = false
                    contactsModel.filter = searchField.text
                }
            }
        }

        SilicaListView {
            id: listView
            model: contactsModel
            delegate: listDelegate
            anchors.top: searchArea.visible ? searchArea.bottom : header.bottom
            width: parent.width
            anchors.bottom: parent.bottom
            clip: true
            cacheBuffer: page.height * 2
            pressDelay: 0
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            section.property: "nickname"
            section.criteria: ViewSection.FirstCharacter
            signal remove(string rmjid)
            /*header: SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Search"

                onTextChanged: {
                    contactsModel.search(searchField.text)
                }
            }*/

            FastScroll {
                id: fastScroll
                listView: listView
                visible: searchArea.visible
            }
        }

        BusyIndicator {
            anchors.centerIn: listView
            size: BusyIndicatorSize.Large
            running: visible
            visible: searchIndicator.visible
        }

        Label {
            anchors.fill: listView
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSizeLarge
            text: qsTr("Contacts list is empty. Sync phonebook or add contacts manually.")
            color: Theme.secondaryHighlightColor
            visible: listView.count == 0
        }

        VerticalScrollDecorator {
            flickable: listView
            visible: !searchArea.visible
        }
    }

    Dialog {
        id: renameContact
        allowedOrientations: Orientation.Portrait
        property string jid
        function showData(ojid, oname) {
            jid = ojid
            nameField.text = oname
            renameContact.open()
            nameField.forceActiveFocus()
            nameField.selectAll()
        }
        canAccept: nameField.text.trim().length > 0

        DialogHeader {
            title: qsTr("Rename contact")
        }

        TextField {
            id: nameField
            anchors.centerIn: parent
            width: parent.width - (Theme.paddingLarge * 2)
            placeholderText: qsTr("Enter new name")
            EnterKey.enabled: text.length > 0
            EnterKey.highlighted: text.length > 0
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: renameContact.accept()
        }

        onAccepted: {
            nameField.deselect()
            contactsModel.renameContact(renameContact.jid, nameField.text)
            selectContact.contactsChanged()
        }

        onDone: {
            nameField.focus = false
            listView.forceActiveFocus()
        }
    }

    Dialog {
        id: newGroup
        allowedOrientations: Orientation.Portrait
        canAccept: groupTitle.text.trim().length > 0

        onStatusChanged: {
            if (status == DialogStatus.Opened) {
                groupTitle.text = ""
                groupTitle.forceActiveFocus()
            }
        }

        onAccepted: {
            groupTitle.deselect()
            whatsapp.createGroup(groupTitle.text.trim())
            groupTitle.focus = false
            roster.forceActiveFocus()
        }

        DialogHeader {
            title: qsTr("Create group")
        }

        TextField {
            id: groupTitle
            anchors.centerIn: parent
            width: parent.width - (Theme.paddingLarge * 2)
            placeholderText: qsTr("Write name of new group here")
            EnterKey.enabled: false
        }
    }

    RemorsePopup {
        id: remorseDisconnect
    }

    ContactsModel {
        id: contactsModel
        notifyEvents: true
    }

    Component {
        id: listDelegate
        Rectangle {
            id: itemDelegate
            width: ListView.view.width
            height: visible ? (Theme.itemSizeMedium + (inMenu.visible ? inMenu.height : 0)) : 0
            color: mArea.pressed ? Theme.secondaryHighlightColor : "transparent"
            visible: model.visible ? (model.jid !== myJid || showMyJid) : false

            Rectangle {
                id: presence
                width: 10
                height: ava.height
                anchors.left: itemDelegate.left
                anchors.verticalCenter: ava.verticalCenter
                color: model.blocked ? "#60FF0000" : (page.connectionStatus == 4 ? (model.available ? "#4000FF00" : "transparent") : "transparent")
            }

            AvatarHolder {
                id: ava
                source: model.avatar == "undefined" ? "" : (model.avatar)
                anchors.left: itemDelegate.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: itemDelegate.top
                anchors.topMargin: Theme.paddingSmall / 2
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge

                Rectangle {
                    id: unreadCount
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    smooth: true
                    radius: Theme.iconSizeSmall / 4
                    border.width: 1
                    border.color: "lightgray"
                    color: Theme.secondaryHighlightColor
                    visible: model.unread > 0
                    anchors.right: parent.right
                    anchors.top: parent.top

                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: model.unread
                        color: Theme.primaryColor
                    }
                }
            }

            Column {
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: ava.verticalCenter
                anchors.right: itemDelegate.right
                anchors.rightMargin: Theme.paddingSmall
                clip: true
                spacing: Theme.paddingSmall

                Label {
                    id: nickname
                    font.pixelSize: Theme.fontSizeMedium
                    width: parent.width
                    text: Utilities.emojify(model.nickname, emojiPath)
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: mArea.pressed ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    id: status
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    text: model.contacttype == 0 ? Utilities.emojify(model.message, emojiPath) : qsTr("Group chat")
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: mArea.pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            MouseArea {
                id: mArea
                anchors.fill: itemDelegate
                onClicked: {
                    conversation.loadContactModel(model)
                    pageStack.push(conversation)
                }
                onPressAndHold: {
                    console.log("last message: " + model.lastmessage)
                    inMenu.show(itemDelegate)
                }
            }

            Connections {
                target: listView
                onRemove: {
                    var rjid = rmjid
                    if (rmjid === model.jid) {
                        console.log("should remove " + rjid)
                        removeItem.execute(itemDelegate,
                                           (rjid.indexOf("-") == -1 ? qsTr("Delete ") : qsTr("Leave group %1").arg(model.nickname)),
                                           function () {
                                               contactsModel.deleteContact(rjid)
                                               if (rjid.indexOf("-") != -1) {
                                                   whatsapp.groupLeave(rjid)
                                               }
                                           },
                                           5000)
                    }
                }
            }

            RemorseItem {
                id: removeItem
                anchors.fill: itemDelegate
            }

            ListView.onRemove: RemoveAnimation {
                target: itemDelegate
            }

            MenuIndicator {
                anchors.bottom: itemDelegate.bottom
                anchors.bottomMargin: inMenu.height - (height / 2)
                width: itemDelegate.width
                visible: inMenu.active
            }

            ContextMenu {
                id: inMenu
                anchors.bottom: itemDelegate.bottom
                width: itemDelegate.width

                MenuItem {
                    text: qsTr("Profile")
                    enabled: (roster.connectionStatus == 4) ? true : (model.jid.indexOf("-") == -1)
                    onClicked: {
                        profileAction(model.jid)
                    }
                }

                MenuItem {
                    text: qsTr("Refresh")
                    enabled: roster.connectionStatus == 4
                    onClicked: {
                        whatsapp.refreshContact(model.jid)
                        banner.notify(qsTr("Contact syncing started..."))
                    }
                }

                MenuItem {
                    text: qsTr("Rename")
                    visible: model.jid.indexOf("-") == -1
                    onClicked: {
                        renameContact.showData(model.jid, model.nickname)
                    }
                }

                MenuItem {
                    text: model.jid.indexOf("-") == -1 ? qsTr("Delete") : qsTr("Leave group")
                    enabled: (roster.connectionStatus == 4) ? true : (model.jid.indexOf("-") == -1)
                    onClicked: {
                        listView.remove(model.jid)
                    }
                }

                MenuItem {
                    text: model.jid.indexOf("-") == -1 ? (model.blocked ? qsTr("Unblock") : qsTr("Block")) : (model.blocked ? qsTr("Unmute") : qsTr("Mute"))
                    enabled: roster.connectionStatus == 4
                    onClicked: {
                        if (model.jid.indexOf("-") == -1)
                            whatsapp.blockOrUnblockContact(model.jid)
                        else
                            whatsapp.muteOrUnmuteGroup(model.jid)
                    }
                }
            }
        }
    }
}
