// FastScroll.qml
import QtQuick 2.0
import Sailfish.Silica 1.0 // for Style
import "FastScroll.js" as Sections
import "Utilities.js" as Utilities

Item {
    id: root

    property ListView listView

    property int __topPageMargin: listView.anchors.topMargin
    property int __bottomPageMargin: listView.anchors.bottomMargin
    property int __leftPageMargin: listView.anchors.leftMargin
    property int __rightPageMargin: listView.anchors.rightMargin
    property bool __hasPageWidth : true
    property bool __hasPageHeight : true

    property int __hideTimeout: 500

    function init() {
        internal.initDirtyObserver();
    }

    function sectionExists(sectionName){

        if(!Sections._sections.length)
            Sections.initSectionData(listView)


       // consoleDebug("Check "+sectionName +" IN "+Sections._sections.join(","))
        return Sections._sections.indexOf(sectionName)>=0;
    }

    // This function ensures that we always anchor the decorator correctly according
    // to the page margins.
    function __updatePageMargin() {
        if (!listView)
            return
        /*var p = listView.parent
        while (p) {
            if (p.hasOwnProperty("__isPage")) {
                __hasPageWidth = function() { return p.width == listView.width }
                __topPageMargin = function() { return p.anchors.topMargin }
                __bottomPageMargin = function() { return p.anchors.bottomMargin }
                __leftPageMargin = function() { return p.anchors.leftMargin }
                __rightPageMargin = function() { return p.anchors.rightMargin }
                return;
            } else {
                p = p.parent;
            }
        }*/
    }

    onListViewChanged: {
        if (listView && listView.model) {
            internal.initDirtyObserver();
        } else if (listView) {
            listView.modelChanged.connect(function() {
                if (listView.model) {
                    internal.initDirtyObserver();
                }
            });
        }
        __updatePageMargin()
    }

    anchors.fill: parent

    //FIXME: Item
    Item {
        anchors.fill: parent
        anchors.leftMargin: __hasPageWidth ? -__leftPageMargin : 0
        anchors.rightMargin: __hasPageWidth ? -__rightPageMargin : 0
        anchors.topMargin: __hasPageHeight ? -__topPageMargin : 0
        anchors.bottomMargin: __hasPageHeight ? -__bottomPageMargin : 0

        MouseArea {
            id: dragArea
            objectName: "dragArea"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Theme.itemSizeMedium
            drag.target: magnifier
            drag.axis: Drag.YAxis
            drag.minimumY: 0 // listView.y
            drag.maximumY: dragArea.height - magnifier.height // listView.y + listView.height - magnifier.height

            onPressed: {
                magnifier.positionAtY(dragArea.mouseY);
            }

            onPositionChanged: {
                internal.adjustContentPosition(dragArea.mouseY);
            }

            Rectangle {
                id: rail
                color: Theme.secondaryHighlightColor
                opacity: 0
                anchors.fill: parent

                property bool dragging: dragArea.drag.active

                GlassItem {
                    id: handle
                    opacity: !rail.dragging ? 1 : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Theme.paddingSmall + (rail.height - height)/(1.0 - listView.visibleArea.heightRatio) * listView.visibleArea.yPosition
                    radius: Theme.itemSizeMedium
                }

                states: State {
                    name: "visible"
                    when: listView.moving || rail.dragging
                    PropertyChanges {
                        target: rail
                        opacity: 1
                    }
                }

                transitions: [
                    Transition {
                        from: ""; to: "visible"
                        NumberAnimation {
                            properties: "opacity"
                            duration: root.__hideTimeout
                        }
                    },
                    Transition {
                        from: "visible"; to: ""
                        NumberAnimation {
                            properties: "opacity"
                            duration: root.__hideTimeout
                        }
                    }
                ]
            }
        }

        Rectangle {
            id: magnifier
            objectName: "popup"
            opacity: rail.dragging ? 1 : 0
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.itemSizeExtraLarge
            color: Theme.secondaryHighlightColor

            function positionAtY(yCoord) {
                magnifier.y = Math.max(dragArea.drag.minimumY, Math.min(yCoord - magnifier.height/2, dragArea.drag.maximumY));
            }

            Label {
                id: magnifierLabel
                objectName: "magnifierLabel"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeHuge
                //font.bold: true

                text: Utilities.emojify(internal.currentSection, emojiPath)
            }
        }
    }

    Timer {
        id: dirtyTimer
        interval: 100
        running: false
        onTriggered: {
            Sections.initSectionData(listView);
            internal.modelDirty = false;
        }
    }

    Connections {
        target: root.listView
        onCurrentSectionChanged: internal.curSect = rail.dragging ? internal.curSect : ""
    }

    QtObject {
        id: internal

        property string currentSection: listView.currentSection
        property string curSect: ""
        property string curPos: "first"
        property int oldY: 0
        property bool modelDirty: false
        property bool down: true

        function initDirtyObserver() {
            Sections.initialize(listView);
            function dirtyObserver() {
                if (!internal.modelDirty) {
                    internal.modelDirty = true;
                    dirtyTimer.running = true;
                }
            }

            if (listView.model.countChanged)
                listView.model.countChanged.connect(dirtyObserver);

            if (listView.model.itemsChanged)
                listView.model.itemsChanged.connect(dirtyObserver);

            if (listView.model.itemsInserted)
                listView.model.itemsInserted.connect(dirtyObserver);

            if (listView.model.itemsMoved)
                listView.model.itemsMoved.connect(dirtyObserver);

            if (listView.model.itemsRemoved)
                listView.model.itemsRemoved.connect(dirtyObserver);
        }

        function adjustContentPosition(y) {
            if (y < 0 || y > dragArea.height) return;

            internal.down = (y > internal.oldY);
            var sect = Sections.getClosestSection((y / dragArea.height), internal.down);
            internal.oldY = y;
            if (internal.curSect != sect) {
                internal.curSect = sect;
                internal.curPos = Sections.getSectionPositionString(internal.curSect);
                var sec = Sections.getRelativeSections(internal.curSect);
                internal.currentSection = internal.curSect;
                var idx = Sections.getIndexFor(sect);
                listView.positionViewAtIndex(idx, ListView.Beginning);
            }
        }

    }
}
