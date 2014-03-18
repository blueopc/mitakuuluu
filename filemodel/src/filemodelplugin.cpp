#include "filemodelplugin.h"
#include "filemodel.h"

#include <qqml.h>

void FilemodelPlugin::registerTypes(const char *uri)
{
    // @uri harbour.mitakuuluu.filemodel
    qmlRegisterType<Filemodel>(uri, 1, 0, "Filemodel");
}
