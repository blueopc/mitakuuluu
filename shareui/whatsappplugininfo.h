#ifndef WHATSAPPPLUGININFO_H
#define WHATSAPPPLUGININFO_H

#include <TransferEngine-qt5/transferplugininfo.h>
#include <TransferEngine-qt5/transfermethodinfo.h>

class WhatsappPluginInfo : public TransferPluginInfo
{
    Q_OBJECT
public:
    WhatsappPluginInfo();
    ~WhatsappPluginInfo();
    QList<TransferMethodInfo> info() const;
    void query();
    bool ready() const;

private:
    QList<TransferMethodInfo> m_infoList;
    bool m_ready;

};

#endif // WHATSAPPPLUGININFO_H
