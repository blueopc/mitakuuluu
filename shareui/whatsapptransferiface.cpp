#include "whatsapptransferiface.h"
#include "whatsappplugininfo.h"
#include "whatsappmediatransfer.h"

#include <QtPlugin>

WhatsappTransferIface::WhatsappTransferIface()
{

}

WhatsappTransferIface::~WhatsappTransferIface()
{

}

QString WhatsappTransferIface::pluginId() const
{
    return QLatin1String("MitakuuluuSharePlugin");
}

bool WhatsappTransferIface::enabled() const
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
