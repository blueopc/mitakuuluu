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
            password.text = ""
            codeArea.text = ""
            busyIndicator.visible = false
        }
        onAccountExpired: {
            errorLabel.text = qsTr("Account expired\n") + JSON.stringify(reason)
            busyIndicator.visible = false
            errorArea.visible = true
            phoneField.text = ""
            password.text = ""
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
            password.text = ""
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
            text += qsTr("Code successfully requested.")
        }
        else {
            var reason = reply.reason
            var param = reply.param
            if (reply.param == 'in')
                param = "phone number"
            if (reply.param == 'token')
                param = "secure token"

            if (reply.reason == "too_recent")
                reason = qsTr("Too frequent attempts to request the code.")
            else if (reply.reason == "too_many_guesses")
                reason = qsTr("Too many wrong code guesses.")
            else if (reply.reason == "too_many")
                reason = qsTr("Too many attempts. Try again tomorrow.")
            else if (reply.reason == 'old_version' || reply.reason == 'bad_token')
                reason = qsTr("Protocol version outdated, sorry. Please contact me at coderusinbox@gmail.com or via twitter: @icoderus")
            else if (reply.reason == "stale")
                reason = qsTr("Registration code expired. You need to request a new one.")
            else if (reply.reason == "missing") {
                if (typeof(reply.param) == "undefined")
                    reason = qsTr("Registration code expired. You need to request a new one.")
                else
                    reason = qsTr("Missing request param: %1").arg(param)
            }
            else if (reply.reason == "bad_param") {
                reason = qsTr("Bad parameters passed to code request: %1").arg(param)
            }
            else if (reply.reason == "no_routes")
                reason = qsTr("No cell routes for %1 caused by your operator. Please try other method [sms/voice]").arg(reply.method == 'voice' ? qsTr("making call") : qsTr("sending sms"))
            //else if (reply.reason != "undefined")
            //    text += reply.reason
            text += qsTr("Reason: %1").arg(reason)
        }
        if (reply.retry_after > 0) {
            var retry = reply.retry_after / 60
            var hours = Math.abs(retry / 60)
            var mins = Math.abs(retry % 60)
            var after = ""
            if (hours > 0) {
                after += qsTr("%n hours", "", hours)
                after += " "
            }
            after += qsTr("%n minutes", "", mins)
            text += "\n"
            text += qsTr("You can retry requesting code after %1").arg(after)
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

        Rectangle {
            id: errorArea
            anchors.fill: parent
            color: "#C0FF0000"
            visible: false

            Label {
                id: errorLabel
                anchors.fill: parent
                anchors.margins: Theme.paddingLarge
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
