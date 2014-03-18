import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Ambience 1.0
import Sailfish.TransferEngine 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.signonuiservice 1.0

SplitViewPage {
    id: fullscreenPage

    property variant model
    property int currentIndex: -1
    property string name
    property string path

    signal removeItem

    allowedOrientations: window.allowedOrientations

    Component.onCompleted: slideshowView.positionViewAtIndex(currentIndex, PathView.Center)


    SailfishTransferMethodsModel {
        id: transferMethodsModel
        filter: fullscreenPage.model.get(fullscreenPage.currentIndex).mime//"image/png"
    }

    background: ShareMethodList {
        id: menuList


        objectName: "menuList"
        model:  ransferMethodsModel
        source: fullscreenPage.model.get(fullscreenPage.currentIndex).path
        anchors.fill: parent

        //% "Share"
        listHeader: qsTrId("gallery-la-share")

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                Component {
                    id: detailsComponent
                    DetailsPage {}
                }

                //% "Details"
                text: qsTrId("gallery-me-details")
                onClicked: window.pageStack.push(detailsComponent, {modelItem: model.get(currentIndex)} )
            }

            MenuItem {
                //% "Delete"
                text: qsTrId("gallery-me-delete")
                onClicked: {
                    fullscreenPage.removeItem()
                    pageStack.pop()
                }
            }

            MenuItem {
                //% "Create ambience"
                text: qsTrId("gallery-me-create_ambience")

                onClicked: Ambience.source = model.get(currentIndex).path
            }
        }

        header: Item {
            height: Theme.itemSizeLarge
            width: menuList.width * 0.7 - Theme.paddingLarge
            x: menuList.width * 0.3

            Label {
                text: model.get(currentIndex).name
                width: parent.width
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                anchors.verticalCenter: parent.verticalCenter
                objectName: "imageTitle"
                horizontalAlignment: Text.AlignRight
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
            }
        }

        // Add "add account" to the footer. User must be able to
        // create accounts in a case there are none.
        footer: BackgroundItem {
            Label {
                //% "Add account"
                text: qsTrId("gallery-la-add_account")
                x: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            onClicked: {
                jolla_signon_ui_service.inProcessParent = fullscreenPage
                accountCreator.startAccountCreation()
            }
        }

        SignonUiService {
            id: jolla_signon_ui_service
            inProcessServiceName: "com.jolla.gallery"
            inProcessObjectPath: "/JollaGallerySignonUi"
        }

        AccountCreationManager {
            id: accountCreator
            serviceFilter: ["sharing"]
            endDestination: fullscreenPage
            endDestinationAction: PageStackAction.Pop
        }
    }

    SlideshowView {
        id: slideshowView

        model: fullscreenPage.model
        currentIndex: fullscreenPage.currentIndex
        onCurrentIndexChanged: fullscreenPage.currentIndex = currentIndex
        interactive: model.count > 1

        delegate: MouseArea {
            id: delegate
            property bool isPagePortrait: fullscreenPage.isPortrait
            property bool isSplitActive: fullscreenPage.opened
            property string path: model.path
            width: slideshowView.width
            height: slideshowView.height
            opacity: Math.abs(x) <= slideshowView.width ? 1.0 - (Math.abs(x) / slideshowView.width) : 0
            property bool isCurrent: PathView.isCurrentItem
            onIsCurrentChanged: {
            	if (isCurrent) {
        			fullscreenPage.name = model.name
        			fullscreenPage.path = model.path
        		}
            }
            onIsSplitActiveChanged: photo.updateScale()
            onIsPagePortraitChanged: photo.updateScale()
            onClicked: fullscreenPage.open = !fullscreenPage.open
            Image {
                id: photo
                property bool _isPortrait
                property real scaleFactor

                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                source: model.path
                asynchronous: true
                width: implicitWidth * scaleFactor
                height: implicitHeight * scaleFactor
                Behavior on scaleFactor { NumberAnimation { duration: 300 }}

                onStatusChanged: {
                    if (status == Image.Ready) {
                        photo._isPortrait = implicitWidth < implicitHeight
                        updateScale()
                    }
                }

                function updateScale() {
                    var minimumDimension = Math.min(fullscreenPage.width, fullscreenPage.height)
                    if (fullscreenPage.splitActive) {
                        scaleFactor = minimumDimension / (photo._isPortrait ? photo.implicitWidth : photo.implicitHeight)
                    } else {
                        scaleFactor = delegate.isPagePortrait
                                    ? minimumDimension / photo.implicitWidth
                                    : minimumDimension / photo.implicitHeight
                    }
                }
            }
        }
    }
}
 
