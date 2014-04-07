#include "whatsappmediatransfer.h"

WhatsappMediaTransfer::WhatsappMediaTransfer(QObject *parent) :
    MediaTransferInterface(parent)
{
}

WhatsappMediaTransfer::~WhatsappMediaTransfer()
{

}

bool WhatsappMediaTransfer::cancelEnabled() const
{
    return true;
}

QString WhatsappMediaTransfer::displayName() const
{
    return QString("Mitakuuluu");
}

bool WhatsappMediaTransfer::restartEnabled() const
{
    return false;
}

QUrl WhatsappMediaTransfer::serviceIcon() const
{
    return QUrl("/usr/share/harbour-mitakuuluu2/icons/transferplugin.png");
}

void WhatsappMediaTransfer::cancel()
{
    Q_EMIT statusChanged(MediaTransferInterface::TransferCanceled);
}

void WhatsappMediaTransfer::start()
{
    Q_EMIT statusChanged(MediaTransferInterface::TransferStarted);
    Q_EMIT progressUpdated(1.0);
    Q_EMIT statusChanged(MediaTransferInterface::TransferFinished);
}
