#ifndef WHATSAPPMEDIATRANSFER_H
#define WHATSAPPMEDIATRANSFER_H

#include <TransferEngine-qt5/mediatransferinterface.h>

class WhatsappMediaTransfer : public MediaTransferInterface
{
    Q_OBJECT
public:
    WhatsappMediaTransfer(QObject * parent = 0);
    ~WhatsappMediaTransfer();

    bool	cancelEnabled() const;
    QString	displayName() const;
    bool	restartEnabled() const;
    QUrl	serviceIcon() const;
signals:

public slots:
    void	cancel();
    void	start();

};

#endif // WHATSAPPMEDIATRANSFER_H
