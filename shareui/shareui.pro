TEMPLATE = lib

TARGET = mitakuuluushareplugin
target.path = /usr/lib/nemo-transferengine/plugins

QT += dbus
CONFIG += plugin link_pkgconfig
PKGCONFIG += nemotransferengine-qt5

HEADERS += \
    whatsapptransferiface.h \
    whatsappplugininfo.h \
    whatsappmediatransfer.h

SOURCES += \
    whatsapptransferiface.cpp \
    whatsappplugininfo.cpp \
    whatsappmediatransfer.cpp

INSTALLS += target

OTHER_FILES += transferplugin.json
