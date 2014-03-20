#include "whatsapptransferiface.h"
#include "whatsappplugininfo.h"
#include <QtPlugin>

QString WhatsappTransferIface::pluginId()
{
    return QLatin1String("Mitakuuluu");
}

bool WhatsappTransferIface::enabled()
{
    return true;
}

TransferPluginInfo *WhatsappTransferIface::infoObject()
{
    return new WhatsappPluginInfo;
}

Q_PLUGIN_METADATA(IID "org.coderus.mitakuuluu.share")
