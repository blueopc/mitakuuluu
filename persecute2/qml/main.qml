import QtQuick 2.0
import Sailfish.Silica 1.0
import QtFeedback 5.0
import org.nemomobile.contacts 1.0

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"
    cover: Qt.resolvedUrl("CoverPage.qml")

    property bool sendByEnter: false
    onSendByEnterChanged: settings.setValue("sendByEnter", sendByEnter)

    property bool showTimestamp: true
    onShowTimestampChanged: settings.setValue("showTimestamp", showTimestamp)

    property int fontSize: 32
    onFontSizeChanged: {
        console.log("fontSize: " + fontSize)
        settings.setValue("fontSize", fontSize)
    }

    property bool followPresence: false
    onFollowPresenceChanged: {
        settings.setValue("followPresence", followPresence)
        updateCoverActions()
    }

    property bool showSeconds: true
    onShowSecondsChanged: settings.setValue("showSeconds", showSeconds)

    property bool showMyJid: false
    onShowMyJidChanged: settings.setValue("showMyJid", showMyJid)

    property bool showKeyboard: false
    onShowKeyboardChanged: settings.setValue("showKeyboard", showKeyboard)

    property bool acceptUnknown: true
    onAcceptUnknownChanged: settings.setValue("acceptUnknown", acceptUnknown)

    property bool notifyActive: true
    onNotifyActiveChanged: settings.setValue("notifyActive", notifyActive)

    property bool resizeImages: false
    onResizeImagesChanged: settings.setValue("resizeImages", resizeImages)

    property bool resizeBySize: true
    onResizeBySizeChanged: settings.setValue("resizeBySize", resizeBySize)

    property int resizeImagesTo: 1048546
    onResizeImagesToChanged: settings.setValue("resizeImagesTo", resizeImagesTo)

    property double resizeImagesToMPix: 5.01
    onResizeImagesToMPixChanged: settings.setValue("resizeImagesToMPix", resizeImagesToMPix)

    property string conversationTheme: "/usr/share/harbour-mitakuuluu/qml/DefaultDelegate.qml"
    onConversationThemeChanged: settings.setValue("conversationTheme", conversationTheme)

    property int conversationIndex: 0
    onConversationIndexChanged: settings.setValue("conversationIndex", conversationIndex)

    property bool alwaysOffline: false
    onAlwaysOfflineChanged: {
        settings.setValue("alwaysOffline", alwaysOffline)
        if (alwaysOffline)
            whatsapp.setPresenceUnavailable()
        else
            whatsapp.setPresenceAvailable()
        updateCoverActions()
    }
    property bool deleteMediaFiles: false
    onDeleteMediaFilesChanged: settings.setValue("deleteMediaFiles", deleteMediaFiles)

    property bool importToGallery: true
    onImportToGalleryChanged: settings.setValue("importToGallery", importToGallery)

    property bool showConnectionNotifications: false
    onShowConnectionNotificationsChanged: settings.setValue("showConnectionNotifications", showConnectionNotifications)

    property bool lockPortrait: false
    onLockPortraitChanged: settings.setValue("lockPortrait", lockPortrait)

    property string connectionServer: "c3.whatsapp.net"
    onConnectionServerChanged: {
        console.log("set connectionServer: " + connectionServer)
        settings.setValue("connectionServer", connectionServer)
    }

    property bool notificationsMuted: false
    onNotificationsMutedChanged: {
        settings.setValue("notificationsMuted", notificationsMuted)
        updateCoverActions()
    }

    property bool threading: true
    onThreadingChanged: settings.setValue("threading", threading)

    property bool hideKeyboard: false
    onHideKeyboardChanged: settings.setValue("hideKeyboard", hideKeyboard)

    property bool notifyMessages: false
    onNotifyMessagesChanged: settings.setValue("notifyMessages", notifyMessages)

    property bool keepLogs: true
    onKeepLogsChanged: settings.setValue("keepLogs", keepLogs)

    property bool applicationCrashed: false
    property int currentOrientation: pageStack._currentOrientation

    property PeopleModel allContactsModel: PeopleModel {
        filterType: PeopleModel.FilterAll
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

    property string coverIconLeft: "../images/icon-cover-location-left.png"
    property string coverIconRight: "../images/icon-cover-camera-right.png"

    function coverLeftClicked() {
        console.log("coverLeftClicked")
        coverAction(coverLeftAction)
    }

    function coverRightClicked() {
        console.log("coverRightClicked")
        coverAction(coverRightAction)
    }

    function coverAction(index) {
        switch (index) {
        case 0: //exit
            shutdownEngine()
            break
        case 1: //presence
            if (followPresence) {
                followPresence = false
                alwaysOffline = false
            }
            else {
                if (alwaysOffline) {
                    followPresence = true
                }
                else {
                    followPresence = false
                    alwaysOffline = true
                }
            }
            break
        case 2: //global muting
            notificationsMuted = !notificationsMuted
            break
        case 3: //camera
            roster.captureAndSend()
            break
        case 4: //location
            roster.locateAndSend()
            break
        case 5: //voice
            roster.recordAndSend()
            break
        default:
            break
        }
        updateCoverActions()
    }

    property int coverLeftAction: 4
    onCoverLeftActionChanged: {
        settings.setValue("coverLeftAction", coverLeftAction)
        updateCoverActions()
    }
    property int coverRightAction: 3
    onCoverRightActionChanged: {
        settings.setValue("coverRightAction", coverRightAction)
        updateCoverActions()
    }

    function updateCoverActions() {
        coverIconLeft = getCoverActionIcon(coverLeftAction, true)
        coverIconRight = getCoverActionIcon(coverRightAction, false)
    }

    function getCoverActionIcon(index, left) {
        switch (index) {
        case 0: //quit
            return "../images/icon-cover-quit-" + (left ? "left" : "right") + ".png"
        case 1: //presence
            if (followPresence)
                return "../images/icon-cover-autoavailable-" + (left ? "left" : "right") + ".png"
            else {
                if (alwaysOffline)
                    return "../images/icon-cover-unavailable-" + (left ? "left" : "right") + ".png"
                else
                    return "../images/icon-cover-available-" + (left ? "left" : "right") + ".png"
            }
        case 2: //global muting
            if (notificationsMuted)
                return "../images/icon-cover-muted-" + (left ? "left" : "right") + ".png"
            else
                return "../images/icon-cover-unmuted-" + (left ? "left" : "right") + ".png"
        case 3: //camera
            return "../images/icon-cover-camera-" + (left ? "left" : "right") + ".png"
        case 4: //location
            return "../images/icon-cover-location-" + (left ? "left" : "right") + ".png"
        case 5: //recorder
            return "../images/icon-cover-recorder-" + (left ? "left" : "right") + ".png"
        default:
            return ""
        }
    }

    function shutdownEngine() {
        whatsapp.shutdown()
        Qt.quit()
    }

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
            if (jid == roster.myJid)
                pageStack.push(accountPage)
            else {
                userProfile.jid = jid
                pageStack.push(userProfile)
            }
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
        whatsapp.windowActive()
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            console.log("[PageStack] " + pageStack.currentPage.objectName)
        }
    }


    Component.onCompleted: {
        settings.sync()
        var connectionStatus = whatsapp.connectionStatus()
        if (connectionStatus === 5 || connectionStatus === 8)
            pageStack.replace(register)
        else
            pageStack.replace(roster)
        applicationCrashed = !settings.value("selfkill", true)
        sendByEnter = settings.value("sendByEnter", false)
        showTimestamp = settings.value("showTimestamp", true)
        fontSize = settings.value("fontSize", 32)
        followPresence = settings.value("followPresence", false)
        showSeconds = settings.value("showSeconds", true)
        showMyJid = settings.value("showMyJid", false)
        showKeyboard = settings.value("showKeyboard", false)
        acceptUnknown = settings.value("acceptUnknown", true)
        notifyActive = settings.value("notifyActive", true)
        resizeImages = settings.value("resizeImages", false);
        resizeBySize = settings.value("resizeBySize", true)
        resizeImagesTo = settings.value("resizeImagesTo", parseInt(1048546))
        resizeImagesToMPix = settings.value("resizeImagesToMPix", parseFloat(5.01))
        conversationTheme = settings.value("conversationTheme", "/usr/share/harbour-mitakuuluu/qml/DefaultDelegate.qml")
        alwaysOffline = settings.value("alwaysOffline", false)
        deleteMediaFiles = settings.value("deleteMediaFiles", false)
        importToGallery = settings.value("importmediatogallery", true)
        showConnectionNotifications = settings.value("showConnectionNotifications", false)
        lockPortrait = settings.value("lockPortrait", false)
        connectionServer = settings.value("connectionServer", "c.whatsapp.net")
        threading = settings.value("threading", true)
        hideKeyboard = settings.value("hideKeyboard", false)
        notifyMessages = settings.value("notifyMessages", false)
        keepLogs = settings.value("keepLogs", true)
        notificationsMuted = settings.value("notificationsMuted", false)
        coverLeftAction = settings.value("coverLeftAction", 4)
        coverRightAction = settings.value("coverRightAction", 3)

        updateCoverActions()
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

    MediaDialog {
        id: selectMedia
    }

    Popup {
        id: banner
    }

    HapticsEffect {
        id: vibration
        intensity: 1.0
        duration: 200
        attackTime: 250
        fadeTime: 250
        attackIntensity: 0.0
        fadeIntensity: 0.0
    }

    Dialog {
        id: renewDialog

        onAccepted: whatsapp.renewAccount()

        Flickable {
            anchors.fill: parent
            contentHeight: cnt.height
            Column {
                id: cnt
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                spacing: Theme.paddingLarge
                DialogHeader {
                    acceptText: qsTr("Renew")
                }
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("Your WhatsApp subscription expired.\nClick Renew to purchase one year of WhatsApp service.")
                }
            }
        }
    }
}

