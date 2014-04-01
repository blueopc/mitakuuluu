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
            roster.sendVCard(selectedContact.displayLabel, selectedContact.vCard())
            //pageStack.pop(roster, PageStackAction.Immediate)
        }
        else {
            conversation.sendVCard(selectedContact.displayLabel, selectedContact.vCard())
            //pageStack.pop(conversation, PageStackAction.Immediate)
        }
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            allContactsModel.search("")
            fastScroll.init()
        }
        else if (status == DialogStatus.Closed) {
            searchField.text = ""
        }
    }

    DialogHeader {
        id: header
        title: selectedIndex > -1 ? qsTr("Send contact") : qsTr("Select contact")
    }

    SearchField {
        id: searchField
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
        }
        onTextChanged: {
            if (page.status == DialogStatus.Opened) {
                allContactsModel.search(text)
            }
        }
    }

    SilicaListView {
        id: listView
        anchors {
            top: searchField.bottom
            left: page.left
            right: page.right
            bottom: page.bottom
        }
        model: allContactsModel
        delegate: listDelegate
        section {
            property: "displayLabel"
            delegate: sectionDelegate
            criteria: ViewSection.FirstCharacter
        }

        onCountChanged: {
            fastScroll.init()
        }

        FastScroll {
            id: fastScroll
            __hasPageHeight: false
            listView: listView
        }
    }

    Component {
        id: sectionDelegate
        SectionHeader {
            text: section
        }
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
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

            Column {
                id: content
                anchors {
                    left: avaplaceholder.right
                    right: parent.right
                    margins: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    text: model.displayLabel
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    width: parent.width
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    text: model.person.phoneDetails[0].normalizedNumber
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }
    }
}
