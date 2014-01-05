TARGET = harbour-mitakuuluu
target.path = /usr/bin

QT += sql dbus core quick qml
CONFIG += quick2 qml Qt5Contacts link_pkgconfig
PKGCONFIG += Qt5Contacts sailfishapp mlite5 libexif

INCLUDEPATH += /usr/include/sailfishapp
INCLUDEPATH += /usr/include/qt5/QtContacts
INCLUDEPATH += /usr/include/qt5/QtFeedback

gui.files = qml
gui.path = /usr/share/harbour-mitakuuluu

INCLUDEPATH += /usr/include/mlite5

desktop.files = harbour-mitakuuluu.desktop
desktop.path = /usr/share/applications

icon.files = harbour-mitakuuluu.png
icon.path = /usr/share/icons/hicolor/86x86/apps

images.files = images/
images.path = /usr/share/harbour-mitakuuluu

emoji.files = emoji/
emoji.path = /usr/share/harbour-mitakuuluu

dbus.files = dbus/org.coderus.harbour_mitakuuluu.service
dbus.path = /usr/share/dbus-1/services

INSTALLS = target gui images desktop icon dbus emoji

SOURCES += src/persecute.cpp

SOURCES += \
    src/threadworker/threadworker.cpp \
    src/threadworker/queryexecutor.cpp \
    src/dbusobject.cpp \
    src/contactsmodel.cpp \
    src/conversationmodel.cpp \
    src/WhatsApp.cpp \
    src/filesmodel.cpp \
    src/settings.cpp

HEADERS += \
    src/threadworker/threadworker.h \
    src/threadworker/queryexecutor.h \
    src/constants.h \
    src/dbusobject.h \
    src/contactsmodel.h \
    src/conversationmodel.h \
    src/WhatsApp.h \
    src/filesmodel.h \
    src/settings.h

OTHER_FILES += $$files(rpm/*) \
    qml/About.qml \
    qml/Account.qml \
    qml/Broadcast.qml \
    qml/CheckableItem.qml \
    qml/Conversation.qml \
    qml/Forward.qml \
    qml/GroupProfile.qml \
    qml/InteractionArea.qml \
    qml/PrivacyList.qml \
    qml/Register.qml \
    qml/ResizePicture.qml \
    qml/Roster.qml \
    qml/SelectContact.qml \
    qml/Settings.qml \
    qml/main.qml \
    qml/Popup.qml \
    qml/CoverPage.qml \
    qml/AvatarHolder.qml \
    qml/SelectPicture.qml \
    qml/SelectFile.qml \
    qml/DialogRowsHeader.qml \
    dbus/org.coderus.harbour-mitakuuluu.service \
    harbour-mitakuuluu.desktop \
    harbour-mitakuuluu.png
