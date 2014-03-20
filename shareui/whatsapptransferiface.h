#ifndef WHATSAPPTRANSFERIFACE_H
#define WHATSAPPTRANSFERIFACE_H

#include <TransferEngine-qt5/transferplugininterface.h>
#include <TransferEngine-qt5/transferplugininfo.h>
#include <TransferEngine-qt5/transfermethodinfo.h>

class Q_DECL_EXPORT WhatsappTransferIface : public TransferPluginInterface
{
public:
    QString pluginId();
    bool enabled();
    TransferPluginInfo *infoObject();
};

#endif // WHATSAPPTRANSFERIFACE_H
