import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "about"

    onStatusChanged: {
        if (status === PageStatus.Active) {
            contentArea.scrollToTop()
        }
    }

    Image {
        source: "/usr/share/harbour-mitakuuluu/images/hearts-black.png"
        anchors.top: parent.top
        anchors.right: parent.right
        fillMode: Image.TileVertically
        anchors.bottom: parent.bottom
        opacity: 0.5
    }

    SilicaFlickable {
        id: contentArea
        anchors.fill: page
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        boundsBehavior: Flickable.DragAndOvershootBounds
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "About Mitäkuuluu"
            }

            Label {
                text: "v0.1-21"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Label {
                text: "indie WhatsApp client\nwritten by coderus in 0x7DD\nis dedicated to my beloved"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Label {
                text: "\n\nWe accept donations via"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                text: "PayPal"
                width: 300
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    //Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FWRVSTXQ3JXTC")
                    Qt.openUrlExternally("https://www.paypal.com/ru/cgi-bin/webscr?cmd=_send-money&email=ovi.coderus@gmail.com")
                }
            }

            Label {
                text: "Please select payment type «to family or friends»"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Label {
                text: "\n\nMe and my beloved would be grateful for every cent.\nYour donations makes application better and i can spend more time for development."
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Label {
                text: "\n\nThanks:\nMy beloved, my muse. You always give me new strength to work.\nScorpius for WhatsApp protocol implementation in Qt\nCustodian for your responsiveness and developer experience\nMorpog for application launcher icon"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Label {
                text: "\n\nApplication uses remastered WhatsApp logo and WhatsApp protocol, but it's not licensed by WhatsApp. You using application as-is, suggestions, bugs and new ideas will be accepted by email:"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                text: "e-mail to author"
                width: 300
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Qt.openUrlExternally("mailto:coderusinbox@gmail.com?subject=Mitäkuuluu")
                }
            }

            Label {
                text: "\nThank you for using Mitäkuuluu!\n"
                font.pixelSize: Theme.fontSizeMedium
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
