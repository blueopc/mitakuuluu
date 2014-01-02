TEMPLATE = subdirs
SUBDIRS = whatsapp-server persecute2

locales.files = \
    $${NULL}
locales.path = /usr/share/harbour-mitakuuluu/locales

INSTALLS += locales

OTHER_FILES = \
    rpm/harbour-mitakuuluu.spec \
    rpm/harbour-mitakuuluu.yaml
