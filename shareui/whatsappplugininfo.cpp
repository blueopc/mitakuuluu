#include "whatsappplugininfo.h"

WhatsappPluginInfo::WhatsappPluginInfo()
{
}

QList<TransferMethodInfo> WhatsappPluginInfo::info() const
{
    return infoList;
}

void WhatsappPluginInfo::query()
{
    TransferMethodInfo info;

    QStringList capabilities;
    capabilities << QLatin1String("*");

    info.displayName     = QLatin1String("Mitakuuluu");
    info.userName        = QLatin1String("");
    info.accountId       = 0;
    info.methodId        = QLatin1String("whatsapp-share-ui-plugin");
    info.shareUIPath     = QLatin1String("/usr/share/harbour-mitakuuluu/qml/ShareUI.qml");
    info.capabilitities  = capabilities;
    infoList.clear();
    infoList << info;

    Q_EMIT infoReady();
}

bool WhatsappPluginInfo::ready() const
{
    return true;
}
