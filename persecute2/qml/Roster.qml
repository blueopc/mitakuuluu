import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "roster"

    property int connectionStatus: 0
    onConnectionStatusChanged: {
        if (connectionStatus == 9) {
            renewDialog.open()
        }
    }

    property string myJid: ""
    property string pendingGroup: ""

    property alias contacts: contactsModel

    property int unreadCount: 0

    property bool inStack: true

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            var haveRoster = pageStack.find(function(xpage) {
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
        whatsapp.getMyAccount()
        connectionStatus = whatsapp.connectionStatus()
        contactsModel.contactsChanged()
    }

    Connections {
        target: whatsapp
        onConnectionStatusChanged: {
            connectionStatus = connStatus
            whatsapp.getMyAccount()
        }
        onMyAccount: {
        	myJid = account
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
            if (njid.length > 0) {
                pageStack.pop(roster, PageStackAction.Immediate)
                conversation.loadContactModel(contactsModel.getModel(njid))
                pageStack.push(conversation, {}, PageStackAction.Immediate)
            }
        }
        onUploadMediaFailed: {
            banner.notify(qsTr("Media uploading failed!"), "#A0FF2020")
        }
        onAccountExpired: {
            banner.notify(qsTr("Account expired: %1").arg(reason), "#A0FF2020")
        }
    }

    function parseConnectionStatus(value) {
        var array = [qsTr("Engine crashed"),
                     qsTr("Waiting for connection"),
                     qsTr("Connecting..."),
                     qsTr("Authorization..."),
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
                     Theme.rgba("red", 1.0),
                     Theme.primaryColor,
                     Theme.primaryColor,
                     Theme.rgba("red", 1.0)]
        return array[value]
    }

    function parseConnectionAction(value) {
        var array = [qsTr("Restart engine"),
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

    function captureAndSend() {
        appWindow.activate()
        if (pageStack.currentPage.objectName !== "capture")
            pageStack.push(Qt.resolvedUrl("Capture.qml"), {"broadcastMode": true})
    }

    function sendImage(path) {
        broadcast.openMedia(path)
    }

    function sendLocation(lat, lon, zoom, gmaps) {
        broadcast.openLocation(lat, lon, zoom, gmaps)
    }

    function sendAudioNote(path) {
        broadcast.openRecording(path)
    }

    function locateAndSend() {
        appWindow.activate()
        if (pageStack.currentPage.objectName !== "location")
            pageStack.push(Qt.resolvedUrl("Location.qml"), {"broadcastMode": true})
    }

    function recordAndSend() {
        appWindow.activate()
        if (pageStack.currentPage.objectName !== "recorder")
            pageStack.push(Qt.resolvedUrl("Recorder.qml"), {"broadcastMode": true})
    }

    function selectSendContact() {
        appWindow.activate()
        if (pageStack.currentPage.objectName !== "selectContactCard")
            pageStack.push(Qt.resolvedUrl("SendContactCard.qml"), {"broadcastMode": true})
    }

    function sendVCard(name, vcarddata) {
        broadcast.openVCard(name, avatardata)
    }

    SilicaFlickable {
        id: flick
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
                                                   shutdownEngine()
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
                text: parseConnectionAction(connectionStatus)
                onClicked: {
                    if (connectionStatus < 2) {
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
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.secondaryHighlightColor
            font.bold: pArea.pressed
            visible: listView.count == 0
            text: qsTr("Contacts list is empty. Sync phonebook or add contacts manually.")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            textFormat: Text.RichText

            MouseArea {
                id: pArea
                anchors.fill: parent
                onClicked: menuPeek.start()
            }

            SequentialAnimation {
                id: menuPeek
                PropertyAction {
                    target: flick.pullDownMenu
                    property: "active"
                    value: true
                }
                NumberAnimation {
                    target: flick
                    property: "contentY"
                    to: 0 - 30
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: flick
                    property: "contentY"
                    to: 0
                    duration: 80
                    easing.type: Easing.OutCubic
                }
                PropertyAction {
                    target: flick.pullDownMenu
                    property: "active"
                    value: false
                }
            }
        }

        VerticalScrollDecorator {
            flickable: listView
            visible: !searchArea.visible
        }
    }

    Dialog {
        id: renameContact
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
        canAccept: groupTitle.text.trim().length > 0

        onStatusChanged: {
            if (status == DialogStatus.Opened) {
                groupTitle.text = ""
                groupTitle.forceActiveFocus()
            }
        }

        onDone: {
            groupTitle.focus = false
            page.forceActiveFocus()
        }

        onAccepted: {
            groupTitle.deselect()
            whatsapp.createGroup(groupTitle.text.trim())
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
                height: ava.height
                anchors.left: itemDelegate.left
                anchors.right: ava.left
                anchors.verticalCenter: ava.verticalCenter
                color: model.blocked ? Theme.rgba(Theme.highlightDimmerColor, 0.6) : (page.connectionStatus == 4 ? (model.available ? Theme.rgba(Theme.highlightColor, 0.6) : "transparent") : "transparent")
                border.width: model.blocked ? 1 : 0
                border.color: (page.connectionStatus == 4 && model.blocked) ? Theme.rgba(Theme.highlightColor, 0.6) : "transparent"
                smooth: true
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
                    border.color: Theme.highlightColor
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
                anchors.leftMargin: Theme.paddingMedium
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

            /*MenuIndicator {
                anchors.bottom: itemDelegate.bottom
                anchors.bottomMargin: inMenu.height - (height / 2)
                width: itemDelegate.width
                visible: inMenu.active
            }*/

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
