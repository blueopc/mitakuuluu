TEMPLATE = subdirs
SUBDIRS = whatsapp-server persecute2

locales.files = \
    locales/ar.qm \
    locales/ca.qm \
    locales/de.qm \
    locales/es.qm \
    locales/fa.qm \
    locales/fi.qm \
    locales/fr_FR.qm \
    locales/hr_HR.qm \
    locales/it.qm \
    locales/nl_NL.qm \
    locales/pl_PL.qm \
    locales/pt_BR.qm \
    locales/pt_PT.qm \
    locales/ru_RU.qm \
    locales/sl_SI.qm \
    locales/sv.qm \
    locales/tr.qm \
    locales/zh_HK.qm \
    $${NULL}
locales.path = /usr/share/harbour-mitakuuluu/locales

INSTALLS += locales

OTHER_FILES = \
    rpm/harbour-mitakuuluu.spec \
    rpm/harbour-mitakuuluu.yaml
