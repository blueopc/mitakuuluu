import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Dialog {
    id: page
    objectName: "selectContactCard"

    property int selectedIndex: -1
    property bool broadcastMode: true

    property Person selectedContact

    canAccept: false

    onAccepted: {
        console.log("accepting contact: " + selectedContact.displayLabel)
        if (broadcastMode) {
            pageStack.pop(roster, PageStackAction.Immediate)
            roster.sendVCard(selectedContact.displayLabel, selectedContact.vCard())
        }
        else {
            pageStack.pop(conversation, PageStackAction.Immediate)
            conversation.sendVCard(selectedContact.displayLabel, selectedContact.vCard())
        }
    }

    SilicaListView {
        anchors.fill: parent
        spacing: Theme.paddingLarge
        model: allContactsModel
        delegate: listDelegate

        header: DialogHeader { title: selectedIndex > -1 ? qsTr("Send contact") : qsTr("Select contact") }

        VerticalScrollDecorator {}
    }

    Component {
        id: listDelegate
        BackgroundItem {
            width: parent.width
            height: Theme.itemSizeMedium
            highlighted: down || (page.selectedIndex == index)

            onClicked: {
                if (page.selectedIndex == index) {
                    page.selectedIndex = -1
                    page.selectedContact = undefined
                    page.canAccept = false
                }
                else {
                    page.selectedIndex = index
                    page.selectedContact = model.person
                    page.canAccept = true
                }
            }

            Rectangle {
                id: avaplaceholder
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }

                width: ava.width
                height: ava.height
                color: ava.status == Image.Ready ? "transparent" : "#40FFFFFF"

                Image {
                    id: ava
                    width: Theme.itemSizeMedium
                    height: width
                    source: model.person.avatarPath
                    cache: true
                    asynchronous: true
                }
            }

            Label {
                anchors {
                    top: avaplaceholder.top
                    left: avaplaceholder.right
                    right: parent.right
                    leftMargin: Theme.paddingLarge
                    rightMargin: Theme.paddingLarge
                }

                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                text: model.person.displayLabel
            }

            Label {
                anchors {
                    bottom: avaplaceholder.bottom
                    left: avaplaceholder.right
                    right: parent.right
                    leftMargin: Theme.paddingLarge
                    rightMargin: Theme.paddingLarge
                }

                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                text: model.person.phoneDetails[0].normalizedNumber
            }
        }
    }
}
