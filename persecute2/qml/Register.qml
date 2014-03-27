import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "registration"

    property string phoneNumber: ""
    property string code: ""

    onStatusChanged: {
        if (status === PageStatus.Active && !busyIndicator.visible) {
            phoneDialog.open(false, PageStackAction.Immediate)
            phoneField.forceActiveFocus()
        }
    }

    Connections {
        target: whatsapp
        onRegistered: {
            regTimeout.stop()
            pageStack.replace(roster)
        }
        onRegistrationFailed: {
            errorLabel.text = qsTr("Registration failed\n\n") + parseServerReply(reason)
            errorArea.visible = true
            phoneField.text = ""
            codeArea.text = ""
            busyIndicator.visible = false
        }
        onAccountExpired: {
            errorLabel.text = qsTr("Account expired\n") + JSON.stringify(reason)
            busyIndicator.visible = false
            errorArea.visible = true
            phoneField.text = ""
            codeArea.text = ""            
            renewDialog.open()
        }
        onExistsRequestFailed: {
            banner.notify(qsTr("No exists information for your account."))
            busyIndicator.visible = false
            codeDialog.open(false, PageStackAction.Immediate)
        }
        onCodeRequestFailed: {
            errorLabel.text = qsTr("Code request failed\n\n") + parseServerReply(serverReply)
            busyIndicator.visible = false
            errorArea.visible = true
            phoneField.text = ""
            codeArea.text = ""
            phoneDialog.open(false, PageStackAction.Immediate)
        }
        onCodeRequested: {
            banner.notify(qsTr("Activation code requested. Wait for %1 soon").arg(reqSms.checked ? qsTr("sms message") : qsTr("voice call")))
            busyIndicator.visible = false
            codeDialog.open(false, PageStackAction.Immediate)
            codeArea.forceActiveFocus()
        }
        onCodeReceived: {
            pageStack.pop(page, PageStackAction.Immediate)
            actionLabel.text = qsTr("Registering account...")
            busyIndicator.visible = true
            codeArea.focus = false
            page.forceActiveFocus()
        }
        onRegistrationComplete: {
            banner.notify(qsTr("Successfully registered in WhatsApp!"))
            busyIndicator.visible = false
            phoneField.text = ""
            codeArea.text = ""
            pageStack.clear()
            pageStack.push(roster)
        }
        onDissectError: {
            banner.notify(qsTr("Cannot detect your country code. You should use international number format for registration."))
            busyIndicator.visible = false
            errorArea.visible = true
            phoneField.text = ""
            codeArea.text = ""
            phoneDialog.open(false, PageStackAction.Immediate)
        }
    }

    function parseServerReply(reply) {
        var text = ""
        if (reply.status == "sent") {
            text += "Code successfully requested.\n"
        }
        else {
            text += "Reason: "
            if (reply.reason == "too_recent")
                text += "too frequent attempts to request the code"
            else if (reply.reason == "too_many_guesses")
                text += "too many wrong code guesses"
            else if (reply.reason == "too_many")
                text += "too many attempts. try again tomorrow"
            else if (reply.reason == 'old_version' || reply.reason == 'bad_token')
                text += "Protocol version outdated, sorry. Please contact me at coderusinbox@gmail.com or via twitter: @icoderus"
            else if (reply.reason == "stale")
                text = "too many attempts. try again tomorrow"
            else if (reply.reason == "missing") {
                if (typeof(reply.param) == "undefined")
                    text += "Registration code expired. You need to request a new one."
                else
                    text += "Missing request param: " + reply.param
            }
            else if (reply.reason == "bad_param") {
                text += "bad parameters passed to code request: "
                if (reply.param == 'in')
                    text += "phone number"
                if (reply.param == 'token')
                    text += "secure token"
                else
                    text += reply.param
            }
            else if (reply.reason == "no_routes")
                text += "no cell routes to " + (reply.method == 'voice' ? "make call" : 'send sms') + " for your operator. Please try other method [sms/voice]"
            else if (reply.reason != "undefined")
                text += reply.reason
        }
        if (reply.retry_after > 0) {
            var retry = reply.retry_after / 60
            var hours = retry / 60
            var mins = retry % 60
            text += "You can retry requesting code after "
            if (hours > 0)
                text += hours + " hour(s) "
            text += mins + "minute(s)."
        }
        return text
    }

    SilicaFlickable {
        anchors.fill: page

        PageHeader {
            id: titleBar
            title: qsTr("Registration")
        }

        BusyIndicator {
            id: busyIndicator
            size: BusyIndicatorSize.Large
            anchors.centerIn: parent
            running: visible
            visible: false
        }

        Label {
            id: actionLabel
            anchors.top: busyIndicator.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - (Theme.paddingLarge * 2)
            horizontalAlignment: Text.AlignHCenter
            visible: busyIndicator.visible
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: errorArea
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            color: "#C0FF0000"
            visible: false

            Label {
                id: errorLabel
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: errorArea.visible
            onClicked: {
                errorArea.visible = false
                errorLabel.text = ""
                phoneDialog.open(false, PageStackAction.Immediate)
            }
        }
    }

    Dialog {
        id: phoneDialog
        objectName: "phoneDialog"

        onAccepted: {
            whatsapp.regRequest(phoneField.text.trim(), reqSms.checked ? "sms" : "voice", password.text)
            actionLabel.text = qsTr("Checking account...")
            busyIndicator.visible = true
            codeArea.focus = false
            page.forceActiveFocus()
        }

        canAccept: phoneField.acceptableInput && phoneField.text.trim().length > 0

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: phoneRow.height

            Column {
                id: phoneRow
                width: parent.width
                spacing: Theme.paddingLarge

                DialogHeader {
                    title: qsTr("Registration")
                }

                Item {
                    height: phoneField.height
                    width: parent.width - (Theme.paddingLarge * 2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        id: plusSign
                        text: "+"
                        anchors.top: phoneField.top
                        anchors.topMargin: Theme.paddingSmall
                        anchors.right: phoneField.left
                        anchors.rightMargin: - Theme.paddingMedium
                    }
                    TextField {
                        id: phoneField
                        validator: RegExpValidator{ regExp: /[0-9]*/;}
                        anchors.right: parent.right
                        width: parent.width - plusSign.width
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        placeholderText: qsTr("Enter phone number here")
                        onTextChanged: {
                            if (text.indexOf(/[^0-9]/) !== -1) {
                                console.log("have incorrect symbols inside")
                            }
                        }
                        EnterKey.enabled: false
                    }
                }

                TextField {
                    id: password
                    width: parent.width
                    placeholderText: qsTr("Salt password")
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                    echoMode: TextInput.Password
                    EnterKey.enabled: false
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: qsTr("Randomize your registration token")
                    horizontalAlignment: Text.AlignHCenter
                }

                Item {
                    height: reqSms.height
                    width: parent.width - (Theme.paddingLarge * 2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Switch {
                        id: reqSms
                        anchors.left: parent.left
                        icon.source: "image://theme/icon-l-message"
                        checked: true
                        onClicked: {
                            reqVoice.checked = !checked
                        }
                    }

                    Switch {
                        id: reqVoice
                        anchors.right: parent.right
                        icon.source: "image://theme/icon-l-answer"
                        checked: false
                        onClicked: {
                            reqSms.checked = !checked
                        }
                    }
                }

                Button {
                    id: haveCode
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("I have registration code")
                    enabled: phoneDialog.canAccept
                    onClicked: {
                        codeDialog.open(false, PageStackAction.Immediate)
                        codeArea.forceActiveFocus()
                    }
                }
            }
        }
    }

    Dialog {
        id: codeDialog
        objectName: "codeDialog"

        onAccepted: {
            whatsapp.enterCode(phoneField.text.trim(), codeArea.text.trim())
            pageStack.pop(page, PageStackAction.Immediate)
            actionLabel.text = qsTr("Registering account...")
            busyIndicator.visible = true
            codeArea.focus = false
            page.forceActiveFocus()
        }

        onRejected: {
            phoneDialog.open(true, PageStackAction.Immediate)
            phoneField.forceActiveFocus()
        }

        canAccept: codeArea.acceptableInput && codeArea.text.trim().length > 0

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: regColumn.height

            Column {
                id: regColumn
                spacing: Theme.paddingLarge
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.centerIn: parent

                DialogHeader {
                    title: qsTr("Registration")
                }

                Label {
                    text: qsTr("Enter registration code. 6-digits, no '-' sign.")
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                TextField {
                    id: codeArea
                    validator: RegExpValidator { regExp: /^[0-9]{6}$/; }
                    //errorHighlight: text.trim().length !== 6
                    width: parent.width - (Theme.paddingLarge * 2)
                    inputMethodHints: Qt.ImhDigitsOnly
                    anchors.horizontalCenter: parent.horizontalCenter
                    placeholderText: qsTr("Tap here to enter code")
                    EnterKey.enabled: false
                }
            }
        }
    }
}
