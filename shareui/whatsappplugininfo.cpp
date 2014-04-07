#include "whatsappplugininfo.h"

WhatsappPluginInfo::WhatsappPluginInfo()
{
}

WhatsappPluginInfo::~WhatsappPluginInfo()
{

}

QList<TransferMethodInfo> WhatsappPluginInfo::info() const
{
    return m_infoList;
}

void WhatsappPluginInfo::query()
{
    TransferMethodInfo info;

    QStringList capabilities;
    capabilities << QLatin1String("image/*")
                 << QLatin1String("audio/*")
                 << QLatin1String("video/*")
                 << QLatin1String("text/vcard");

    info.displayName     = QLatin1String("Mitakuuluu");
    info.methodId        = QLatin1String("MitakuuluuSharePlugin");
    info.shareUIPath     = QLatin1String("/usr/share/harbour-mitakuuluu/shareui/ShareUI.qml");
    info.capabilitities  = capabilities;
    m_infoList.clear();
    m_infoList << info;

    m_ready = true;
    Q_EMIT infoReady();
}

bool WhatsappPluginInfo::ready() const
{
    return m_ready;
}
