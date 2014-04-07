#ifndef WHATSAPPTRANSFERIFACE_H
#define WHATSAPPTRANSFERIFACE_H

#include <TransferEngine-qt5/transferplugininterface.h>
#include <TransferEngine-qt5/transferplugininfo.h>
#include <TransferEngine-qt5/transfermethodinfo.h>
#include <TransferEngine-qt5/mediatransferinterface.h>

class WhatsappTransferIface : public QObject, public TransferPluginInterface
{
    Q_PLUGIN_METADATA(IID "harbour.mitakuuluu.transfer.plugin")
    Q_INTERFACES(TransferPluginInterface)
public:
    WhatsappTransferIface();
    ~WhatsappTransferIface();

    QString pluginId() const;
    bool enabled() const;
    TransferPluginInfo *infoObject();
    MediaTransferInterface *transferObject();
};

#endif // WHATSAPPTRANSFERIFACE_H
