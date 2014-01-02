import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"
    cover: Qt.resolvedUrl("CoverPage.qml")
    allowedOrientations: Orientation.Portrait

    property bool sendByEnter: false
    property bool showTimestamp: true
    property int fontSize: Theme.fontSizeMedium
    property bool followPresence: false
    property bool showSeconds: true
    property bool showMyJid: false
    property bool showKeyboard: false
    property bool acceptUnknown: true
    property bool notifyActive: true
    //property bool softbankReplacer: false
    property bool resizeImages: false
    property bool resizeBySize: false
    property int resizeImagesTo: 1048546
    property int resizeImagesToMPix: 5
    property string conversationTheme: "/usr/share/harbour-mitakuuluu/qml/DefaultDelegate.qml"
    property int conversationIndex: 0
    property bool alwaysOffline: false
    property bool asynchronousDelegate: true

    property bool applicationCrashed: false
    property int currentOrientation: pageStack._currentOrientation

    onCurrentOrientationChanged: {
        if (Qt.inputMethod.visible) {
            Qt.inputMethod.hide()
        }
        pageStack.currentPage.forceActiveFocus()
    }

    function profileAction(jid) {
        if (jid.indexOf("-") !== -1) {
            pageStack.push(groupPage)
            groupPage.loadContact(roster.getContactModel(jid))
        }
        else {
            userProfile.jid = jid
            pageStack.push(userProfile)
        }
    }

    function bytesToSize(bytes) {
        var sizes = [ qsTr('n/a'), qsTr('bytes'), qsTr('KiB'), qsTr('MiB'), qsTr('GiB')]
        var i = +Math.floor(Math.log(bytes) / Math.log(1024))
        return  (bytes / Math.pow(1024, i)).toFixed( i ? 1 : 0 ) + ' ' + sizes[ isNaN( bytes ) ? 0 : i+1 ]
    }

    onApplicationActiveChanged: {
        console.log("Application " + (applicationActive ? "active" : "inactive"))
        if (pageStack.currentPage == conversation) {
            if (applicationActive) {
                whatsapp.setActiveJid(conversation.jid)
            }
            else {
                whatsapp.setActiveJid("")
            }
        }
        if (followPresence && roster.connectionStatus == 4) {
            if (applicationActive) {
                whatsapp.setPresenceAvailable()
            }
            else {
                whatsapp.setPresenceUnavailable()
            }
        }
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            console.log("[PageStack] " + pageStack.currentPage.objectName)
        }
    }


    Component.onCompleted: {
        var connectionStatus = whatsapp.connectionStatus()
        if (connectionStatus === 5 || connectionStatus === 8)
            pageStack.replace(register)
        else
            pageStack.replace(roster)
        applicationCrashed = !settings.value("selfkill", true)
        sendByEnter = settings.value("sendByEnter", false)
        showTimestamp = settings.value("showTimestamp", true)
        fontSize = settings.value("fontSize", Theme.fontSizeMedium)
        followPresence = settings.value("followPresence", false)
        showSeconds = settings.value("showSeconds", true)
        showMyJid = settings.value("showMyJid", false)
        showKeyboard = settings.value("showKeyboard", false)
        acceptUnknown = settings.value("acceptUnknown", true)
        notifyActive = settings.value("notifyActive", true)
        //softbankReplacer = settings.value("softbankReplacer", false)
        resizeImages = settings.value("resizeImages", false);
        resizeBySize = settings.value("resizeBySize", true)
        resizeImagesTo = settings.value("resizeImagesTo", parseInt(1048576))
        resizeImagesToMPix = settings.value("resizeImagesToMPix", parseInt(5))
        conversationTheme = settings.value("conversationTheme", "/usr/share/harbour-mitakuuluu/qml/DefaultDelegate.qml")
        alwaysOffline = settings.value("alwaysOffline", false)
        asynchronousDelegate = settings.value("asynchronousDelegate", true)
    }

    AddContact {
        id: addContact
    }

    RemovePage {
        id: removePage
    }

    UserProfile {
        id: userProfile
    }

    SelectPhonebook {
        id: selectPhonebook
    }

    SelectFile {
        id: selectFile
    }

    About {
        id: aboutPage
    }

    Account {
        id: accountPage
    }

    Forward {
        id: forwardMessage
    }

    Settings {
        id: settingsPage
    }

    Broadcast {
        id: broadcast
    }

    MutedGroups {
        id: mutedGroups
    }

    PrivacyList {
        id: privacyList
    }

    ResizePicture {
        id: resizePicture
        maximumSize: 480
        minimumSize: 64
        avatar: true
    }

    SelectContact {
        id: selectContact
    }

    SelectPicture {
        id: selectPicture
    }

    Register {
        id: register
    }

    Roster {
        id: roster
    }

    Conversation {
        id: conversation
    }

    GroupProfile {
        id: groupPage
    }

    Popup {
        id: banner
    }
}

