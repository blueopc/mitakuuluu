#ifndef WHATSAPP_H
#define WHATSAPP_H

#include <QObject>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QStringList>
#include <QtDBus/QtDBus>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>

#include <QtContacts/QtContacts>
#include <QtContacts/QContactManager>
#include <QtContacts/QContactFetchRequest>
#include <QtContacts/QContactDetailFilter>
#include <QtContacts/QContactName>
#include <QtContacts/QContactPhoneNumber>
#include <QtContacts/QContactAvatar>

#include <libexif/exif-loader.h>
#include <libexif/exif-entry.h>
#include <libexif/exif-data.h>

using namespace QtContacts;

class WhatsApp: public QObject
{
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)
    Q_PROPERTY(bool online READ isOnline FINAL)
    Q_PROPERTY(bool networkAvailable READ isNetwork FINAL)
    Q_OBJECT

public:
    //friend class DBClient;
    WhatsApp(QObject *parent = 0);
    ~WhatsApp();

private:
    bool isActive();
    bool isOnline();
    bool isNetwork();

    QNetworkAccessManager *nam;
    bool _active;
    bool _online;
    bool _network;
    QString _pendingJid;

    QDBusInterface *iface;

    QTranslator translator;

signals:
    void ready();
    void activeChanged();
    void connectionStatusChanged(int connStatus);
    void messageReceived(QVariantMap data);
    void disconnected(QString reason);
    void authFail(QString username, QString reason);
    void authSuccess(QString username);
    void networkChanged(bool value);
    void noAccountData();
    void registered();
    void smsTimeout(int timeout);
    void registrationFailed(QVariantMap reason);
    void registrationComplete();
    void accountExpired(QVariantMap reason);
    void gotAccountData(QString username, QString password);
    void codeRequested(QVariantMap method);
    void existsRequestFailed(QVariantMap serverReply);
    void codeRequestFailed(QVariantMap serverReply);
    void messageStatusUpdated(QString mjid, QString msgId, int msgstatus);
    void pictureUpdated(QString pjid, QString path);
    void contactsChanged();
    void contactChanged(QVariantMap data);
    void contactSynced(QVariantMap data);
    void newGroupSubject(QVariantMap data);
    void notificationOpenJid(QString njid);
    void setUnread(QString jid, int count);
    void myAccount(QString account);
    void pushnameUpdated(QString mjid, QString pushName);
    void presenceAvailable(QString mjid);
    void presenceUnavailable(QString mjid);
    void presenceLastSeen(QString mjid, int seconds);
    void mediaDownloadProgress(QString mjid, QString msgId, int progress);
    void mediaDownloadFinished(QString mjid, QString msgId, QString path);
    void mediaDownloadFailed(QString mjid, QString msgId);
    void groupParticipant(QString gjid, QString pjid);
    void groupInfo(QVariantMap group);
    void groupCreated(QString gjid);
    void participantAdded(QString gjid, QString pjid);
    void participantRemoved(QString gjid, QString pjid);
    void contactsBlocked(QStringList list);
    void activeJidChanged(QString ajid);
    void contactTyping(QString cjid);
    void contactPaused(QString cjid);
    void synchronizationFinished();
    void synchronizationFailed();
    void phonebookReceived(QVariantList contactsmodel);
    void uploadMediaFailed(QString mjid, QString msgId);
    void groupsMuted(QStringList jids);
    void codeReceived();
    void dissectError();

public slots:
    void exit();
    void setPendingJid(const QString &jid);

    int connectionStatus();
    void authenticate();
    void init();
    void disconnect();
    void sendMessage(const QString &jid, const QString &message, const QString &media, const QString &mediaData);
    void sendBroadcast(const QStringList &jids, const QString &message);
    void sendText(const QString &jid, const QString &message);
    void syncContactList();
    void setActiveJid(const QString &jid);
    QString shouldOpenJid();
    QString getMyAccount();
    void startTyping(const QString &jid);
    void endTyping(const QString &jid);
    bool getAvailable(const QString &jid);
    void downloadMedia(const QString &msgId, const QString &jid);
    void cancelDownload(const QString &msgId, const QString &jid);
    void abortMediaDownload(const QString &msgId, const QString &jid);
    void openVCardData(const QString &name, const QString &data);
    void getParticipants(const QString &jid);
    void getGroupInfo(const QString &jid);
    void regRequest(const QString &phone, const QString &method);
    void enterCode(const QString &phone, const QString &code);
    void setGroupSubject(const QString &gjid, const QString &subject);
    void createGroup(const QString &subject);
    void groupLeave(const QString &gjid);
    void setPicture(const QString &jid, const QString &path);
    void removeParticipant(const QString &gjid, const QString &jid);
    void addParticipant(const QString &gjid, const QString &jid);
    void refreshContact(const QString &jid);
    QString transformPicture(const QString &filename, const QString &jid, int posX, int posY, int sizeW, int sizeH, int maxSize, int rotation);
    void copyToClipboard(const QString &text);
    void blockOrUnblockContact(const QString &jid);
    void sendBlockedJids(const QStringList &jids);
    void muteOrUnmuteGroup(const QString &jid);
    void muteGroups(const QStringList &jids);
    void getPrivacyList();
    void getMutedGroups();
    void forwardMessage(const QStringList &jids, const QString &jid, const QString &msgid);
    void setMyPushname(const QString &pushname);
    void setMyPresence(const QString &presence);
    void sendRecentLogs();
    void shutdown();
    bool isCrashed();
    void requestLastOnline(const QString &jid);
    void addPhoneNumber(const QString &name, const QString &phone);
    QStringList getDownloads();
    void sendMedia(const QStringList &jids, const QString &path);
    QString rotateImage(const QString &path, int rotation);
    QString saveImage(const QString &path);
    void openProfile(const QString &name, const QString &phone, const QString avatar = QString());
    void removeAccount();
    void tryGetWazappAcc();
    void tryGetWhatsupAcc();
    void getPhonebook();
    void syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars);
    void setPresenceAvailable();
    void setPresenceUnavailable();
    void syncAllPhonebook();
    void removeAccountFromServer();
    void forceConnection();
    void setLocale(const QString &localeName);
    int getExifRotation(const QString &image);
    void windowActive();
    bool checkAutostart();
    void setAutostart(bool enabled);
};

#endif // WHATSAPP_H
