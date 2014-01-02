/****************************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: John Brooks <john.brooks@jollamobile.com>
** All rights reserved.
**
** This file is part of Sailfish Silica UI component package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in the
**       documentation and/or other materials provided with the distribution.
**     * Neither the name of the Jolla Ltd nor the
**       names of its contributors may be used to endorse or promote products
**       derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
** ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: pageHeader

    x: parent.width - width
    width: headerText.width + Theme.pageStackIndicatorWidth + 2*Theme.paddingLarge // |text|pad-large|indicator|pad-large|
    height: Theme.itemSizeLarge
    opacity: !dialog || dialog.canAccept ? 1.0 : 0.3

    property Item dialog
    property string acceptText: title
    property bool acceptTextVisible

    default property alias _children: headerText.data

    //% "Accept"
    property string title: qsTrId("components-he-dialog_accept")
    property string subtitle: ""

    onAcceptTextChanged: {
        headerText.state = "linked"
    }

    Component.onCompleted: {
        if (!dialog)
            dialog = _findDialog()
        if (!dialog)
            console.log("DialogHeader must have a parent Dialog instance")
    }

    function _findDialog() {
        var r = parent
        while (r && !r.hasOwnProperty('__silica_dialog'))
            r = r.parent
        return r
    }

    Label {
        id: subtitleLabel
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingMedium
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingMedium
        anchors.bottom: parent.bottom
        color: Theme.secondaryColor
        text: subtitle
        elide: Text.ElideLeft
        horizontalAlignment: Text.AlignRight
        font {
            pixelSize: Theme.fontSizeExtraSmall
            family: Theme.fontFamily
        }
    }

    Row {
        id: headerText

        anchors.verticalCenter: parent.verticalCenter
        x: Theme.paddingMedium
        spacing: Theme.paddingMedium

        Label {
            id: headerLabel
            // The label text can be linked to the dialog activity; initially it is 'Accept'
            text: acceptTextVisible ? acceptText : title
            color: pageHeader.highlighted ? Theme.highlightColor : Theme.primaryColor
            font {
                pixelSize: Theme.fontSizeLarge
                family: Theme.fontFamilyHeading
            }
        }

        states: State {
            // In "linked" state, the visible header is linked to the acceptText content
            name: "linked"

            PropertyChanges {
                target: pageHeader
                acceptTextVisible: true
            }
        }

        transitions: Transition {
            to: "linked"
            SequentialAnimation {
                FadeAnimation { target: headerText; to: 0.0 }
                PropertyAction { target: pageHeader; property: "acceptTextVisible"; value: true }
                FadeAnimation { target: headerText; to: 1.0}
            }
        }

        Timer {
            id: linkTimer
            interval: 1000
            running: false
            repeat: false
            onTriggered: if (acceptText !== "" && acceptText !== title) headerText.state = "linked"
        }

        Connections {
            target: dialog
            onStatusChanged: {
                if (dialog.status == PageStatus.Activating) {
                    headerText.state = ""
                    pageHeader.acceptTextVisible = false
                } else if (dialog.status == PageStatus.Active) {
                    linkTimer.running = true
                }
            }
            onVisibleChanged: {
                if (dialog.status == PageStatus.Active) {
                    // If visiblity changes while we're active - run the linked-change animation again
                    if (!dialog.visible) {
                        headerText.state = ""
                        pageHeader.acceptTextVisible = false
                    } else {
                        linkTimer.running = true
                    }
                }
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 400
        }
    }

    onClicked: { dialog.accept() }

    // for testing
    function _headerText() {
        return headerLabel.text
    }
}

