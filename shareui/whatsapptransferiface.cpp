#include "whatsapptransferiface.h"
#include "whatsappplugininfo.h"
#include "whatsappmediatransfer.h"

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

MediaTransferInterface *WhatsappTransferIface::transferObject()
{
    return new WhatsappMediaTransfer;
}
