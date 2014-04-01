import QtQuick 2.0
import Sailfish.Silica 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    objectName: "forwardMessage"

    property variant jids: []

    property string jid: ""
    property string msgid: ""
    property string msgtext: ""
    property int msgtype: 0
    property string preview: ""
    property string msgdata: ""

    canAccept: listView.count > 0

    onAccepted: {
        conversation.forwardMsg(page.jids, page.msgid)
        page.clear()
    }

    function clear() {
        page.jid = ""
        page.msgid = ""
        page.jids = []
        listModel.clear()
        page.msgtext = ""
        page.msgtype = 0
        page.preview = ""
        page.msgdata = ""
    }

    function loadMessage(model, jid) {
        page.jid = jid
        page.msgid = model.msgid
        if (model.msgtype == 2) {
            msgtext = model.message
            msgtype = 0
        }
        else if (model.mediaurl.length > 0) {
            msgtext = model.mediaurl
            if (model.mediatype == 1) {
                if (model.localurl.length > 0)
                    preview = model.localurl
                else if (model.mediathumb.length > 0)
                    preview = "data:image/png;base64," + model.mediathumb
            }
            if (model.mediathumb.length > 0)
                msgdata = model.mediathumb
            msgdata = model.mediatype
            msgtype = 1
        }
        else if (model.mediatype == 4) {
            msgtext = "Contact: " + model.medianame
            msgdata = model.message
            msgtype = 3
        }
        else if (model.medialat.length > 0 && model.medialon.length > 0) {
            msgtext = model.medialat + "," + msgtext.medialon
            msgtype = 2
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: page

        PullDownMenu {
            MenuItem {
                text: qsTr("Forward to group")
                onClicked: {
                    selectContact.hideGroups = false
                    selectContact.hideContacts = true
                    selectContact.contactsChanged()
                    selectContact.added.connect(listView.forwardTo)
                    pageStack.push(selectContact)
                }
            }

            MenuItem {
                text: qsTr("Add contact")
                onClicked: {
                    selectContact.hideGroups = true
                    selectContact.contactsChanged()
                    selectContact.finished.connect(listView.selectionFinished)
                    pageStack.push(selectContact)
                }
            }
        }

        DialogHeader {
            id: header
            title: qsTr("Forward")
        }

        Label {
            id: msgArea
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            width: (page.isPortrait ? page.width : (page.width / 2)) - Theme.paddingMedium
            text: msgtext
            wrapMode: Text.WordWrap
        }

        Image {
            id: prev
            sourceSize.width: page.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: msgArea.horizontalCenter
            fillMode: Image.PreserveAspectFit
            source: preview
            opacity: page.isPortrait ? 0.2 : 1.0
        }

        SilicaListView {
            id: listView
            anchors.top: page.isPortrait ? msgArea.bottom : header.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: page.isPortrait ? page.width : (page.width / 2)
            clip: true
            model: listModel
            delegate: listDelegate

            function selectionFinished() {
                var jids = selectContact.jids
                page.jids = jids
                for (var i = 0; i < jids.length; i ++) {
                    var model = roster.getContactModel(jids[i])
                    var avatar = (typeof(model.avatar) != "undefined" && model.avatar != "undefined" && model.avatar.length > 0) ? model.avatar : ""
                    listModel.append({"jid": model.jid,
                                      "name": roster.getNicknameByJid(model.jid),
                                      "avatar": avatar})
                }
                selectContact.finished.disconnect(listView.selectionFinished)
            }

            function forwardTo(pjid) {
                selectContact.added.disconnect(listView.forwardTo)
                conversation.forwardMsg(pjid, page.msgid)
                pageStack.pop(page, PageStackAction.Immediate)
                page.reject()
            }
        }

        Label {
            anchors.fill: listView
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.secondaryHighlightColor
            font.bold: pArea.pressed
            visible: listModel.count == 0
            text: qsTr("Select &quot;Add contact&quot; menu item to select contacts")
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
                    target: flickable.pullDownMenu
                    property: "active"
                    value: true
                }
                NumberAnimation {
                    target: flickable
                    property: "contentY"
                    to: 0 - 30
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: flickable
                    property: "contentY"
                    to: 0
                    duration: 80
                    easing.type: Easing.OutCubic
                }
                PropertyAction {
                    target: flickable.pullDownMenu
                    property: "active"
                    value: false
                }
            }
        }

        VerticalScrollDecorator {
            flickable: listView
        }
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: contact
                anchors.left: contactava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: remove.left
                anchors.rightMargin: Theme.paddingMedium
                font.pixelSize: Theme.fontSizeLarge
                text: Utilities.emojify(model.name, emojiPath)
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            IconButton {
                id: remove
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-clear"
                onClicked: {
                    participantsModel.remove(index)
                }
            }
        }
    }

    ListModel {
        id: listModel
    }
}
