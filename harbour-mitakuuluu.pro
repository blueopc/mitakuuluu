TEMPLATE = subdirs
SUBDIRS = \
    whatsapp-server \
    persecute2 \
    #shareui \
    filemodel \
    $${NULL}

locales.files = locales
locales.path = /usr/share/harbour-mitakuuluu

INSTALLS += locales

OTHER_FILES = \
    rpm/harbour-mitakuuluu.spec
