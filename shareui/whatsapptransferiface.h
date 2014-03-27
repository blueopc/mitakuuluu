#ifndef WHATSAPPTRANSFERIFACE_H
#define WHATSAPPTRANSFERIFACE_H

#include <TransferEngine-qt5/transferplugininterface.h>
#include <TransferEngine-qt5/transferplugininfo.h>
#include <TransferEngine-qt5/transfermethodinfo.h>
#include <TransferEngine-qt5/mediatransferinterface.h>

class WhatsappTransferIface : public TransferPluginInterface
{
    Q_PLUGIN_METADATA(IID "org.coderus.mitakuuluu.share" FILE "transferplugin.json")
//    Q_INTERFACES(TransferPluginInterface)
public:
    QString pluginId();
    bool enabled();
    TransferPluginInfo *infoObject();
    MediaTransferInterface *transferObject();
};

#endif // WHATSAPPTRANSFERIFACE_H
