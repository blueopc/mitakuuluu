TARGET = harbour-mitakuuluu
target.path = /usr/bin

QT += sql dbus core multimedia
CONFIG += Qt5Contacts sailfishapp link_pkgconfig
PKGCONFIG += sailfishapp Qt5Contacts mlite5 libexif

INCLUDEPATH += /usr/include/qt5/QtContacts
INCLUDEPATH += /usr/include/qt5/QtFeedback

INCLUDEPATH += /usr/include/mlite5

images.files = images/
images.path = /usr/share/harbour-mitakuuluu

emoji.files = emoji/
emoji.path = /usr/share/harbour-mitakuuluu

dbus.files = dbus/org.coderus.harbour_mitakuuluu.service
dbus.path = /usr/share/dbus-1/services

INSTALLS += images dbus emoji

SOURCES += src/persecute.cpp \
    src/audiorecorder.cpp \
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
    src/settings.h \
    src/audiorecorder.h \
    ../logging/logging.h

OTHER_FILES += $$files(rpm/*) \
    $$files(qml/*) \
    dbus/org.coderus.harbour-mitakuuluu.service \
    harbour-mitakuuluu.desktop \
    harbour-mitakuuluu.png \
    qml/Recorder.qml \
    qml/SendContactCard.qml
