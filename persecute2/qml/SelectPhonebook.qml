import QtQuick 2.0
import Sailfish.Silica 1.0
import org.coderus.mitakuuluu 1.0

Dialog {
    id: page
    objectName: "selectPhonebook"
    allowedOrientations: Orientation.Portrait

    property variant numbers: []
    property variant names: []
    property variant avatars: []

    signal finished

    property variant phonebookmodel

    onStatusChanged: {
        if (status == DialogStatus.Closed) {
            page.finished()
            numbers = []
            names = []
            avatars = []
        }
        else if (status == DialogStatus.Opening) {
            whatsapp.getPhonebook()
        }
    }

    canAccept: numbers.length > 0

    onAccepted: {
        whatsapp.syncContacts(numbers, names, avatars)
        banner.notify(qsTr("Phonebook syncing started..."))
    }

    Connections {
        target: whatsapp
        onPhonebookReceived: {
            phonebookmodel = contactsmodel
            //fastScroll.init()
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        clip: true
        interactive: !listView.flicking
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Sync all phonebook")
                onClicked: {
                    whatsapp.syncAllPhonebook()
                    banner.notify(qsTr("Phonebook syncing started..."))
                    page.reject()
                }
            }

            MenuItem {
                text: qsTr("Add number")
                onClicked: {
                    addContact.open(true, false)
                }
            }

            /*MenuItem {
                text: (page.numbers.length > 0) ? "Deselect all" : "Select all"
                    onClicked: {
                    if (page.numbers.length > 0) {
                        page.numbers = []
                        page.names = []
                        page.avatars = []
                    }
                    else {
                        var vnumbers = []
                        var vnames = []
                        var vavatars = []
                        for (var i = 0; i < phonebookmodel.length; i++) {
                            vnumbers.splice(0, 0, phonebookmodel[i].number)
                            vnames.splice(0, 0, phonebookmodel[i].nickname)
                            vavatars.splice(0, 0, phonebookmodel[i].avatar)
                        }
                        page.numbers = vnumbers
                        page.names = vnames
                        page.avatars = vavatars
                    }
                }
            }*/
        }

        DialogHeader {
            id: header
            title: numbers.length > 0
                   ? ((numbers.length == 1) ? qsTr("Sync contact") : qsTr("Sync %1 contacts").arg(numbers.length))
                   : qsTr("Select contacts")
        }

        SilicaListView {
            id: listView
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            model: phonebookmodel
            delegate: contactsDelegate
            clip: true
            cacheBuffer: page.height * 2
            pressDelay: 0
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            section.property: "modelData"
            section.criteria: ViewSection.FirstCharacter
            section.delegate: Component {
                id: sectionDelegate
                Item {
                    width: parent.width //ListView.view.width
                    height: sectionLabel.paintedHeight
                    Label {
                        id: sectionLabel
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingSmall
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.highlightColor
                        text: section.nickname
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log(section.nickname)
                        }
                    }
                }
            }

            FastScroll {
                id: fastScroll
                listView: listView
            }
        }

        /*VerticalScrollDecorator {
            flickable: listView
        }*/

        BusyIndicator {
            anchors.centerIn: listView
            size: BusyIndicatorSize.Large
            visible: listView.count == 0
            running: visible
        }
    }

    Component {
        id: contactsDelegate

        Rectangle {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            visible: height > 0
            color: checked ? Theme.secondaryHighlightColor : (mArea.pressed ? Theme.secondaryHighlightColor : "transparent")
            property bool checked: page.numbers.indexOf(modelData.number) != -1

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                source: modelData.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: nickname
                font.pixelSize: Theme.fontSizeMedium
                text: modelData.nickname
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: (mArea.pressed || checked) ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: status
                font.pixelSize: Theme.fontSizeSmall
                text: modelData.number
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                color: (mArea.pressed || checked) ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }

            MouseArea {
                id: mArea
                anchors.fill: parent
                onClicked: {
                    var vnumbers = page.numbers
                    var vnames = page.names
                    var vavatars = page.avatars
                    var exists = vnumbers.indexOf(modelData.number)
                    if (exists != -1) {
                        vnumbers.splice(exists, 1)
                        vnames.splice(exists, 1)
                        vavatars.splice(exists, 1)
                    }
                    else {
                        vnumbers.splice(0, 0, modelData.number)
                        vnames.splice(0, 0, modelData.nickname)
                        vavatars.splice(0, 0, modelData.avatar)
                    }
                    page.numbers = vnumbers
                    page.names = vnames
                    page.avatars = vavatars
                }
            }
        }
    }
}
