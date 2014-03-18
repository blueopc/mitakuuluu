TEMPLATE = lib
TARGET = filemodel
QT += quick
QT -= gui
CONFIG += qt plugin

TARGET = $$qtLibraryTarget($$TARGET)
target.path = /usr/lib/qt5/qml/harbour/mitakuuluu/filemodel

SOURCES += \
    src/filemodelplugin.cpp \
    src/filemodel.cpp

HEADERS += \
    src/filemodelplugin.h \
    src/filemodel.h

qmldir.files = qmldir
qmldir.path = /usr/lib/qt5/qml/harbour/mitakuuluu/filemodel

mediasource.files = MitakuuluuMediaSource.qml
mediasource.path = /usr/share/jolla-gallery/mediasources/

qml.files = mediasource
qml.path = /usr/share/harbour-mitakuuluu

INSTALLS += target qmldir mediasource qml
