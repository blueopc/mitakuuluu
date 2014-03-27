#include "whatsappplugininfo.h"

WhatsappPluginInfo::WhatsappPluginInfo()
{
    TransferMethodInfo info;

    QStringList capabilities;
    capabilities << QLatin1String("image/*")
                 << QLatin1String("audio/*")
                 << QLatin1String("video/*")
                 << QLatin1String("text/vcard");

    info.displayName     = QLatin1String("Mitakuuluu");
    info.userName        = "";
    info.accountId       = -1;
    info.methodId        = QLatin1String("whatsapp-share-ui-plugin");
    info.shareUIPath     = QLatin1String("/usr/share/harbour-mitakuuluu/shareui/ShareUI.qml");
    info.capabilitities  = capabilities;
    infoList.clear();
    infoList << info;

    Q_EMIT infoReady();
}

QList<TransferMethodInfo> WhatsappPluginInfo::info() const
{
    return infoList;
}

void WhatsappPluginInfo::query()
{
    Q_EMIT infoReady();
}

bool WhatsappPluginInfo::ready() const
{
    return true;
}
