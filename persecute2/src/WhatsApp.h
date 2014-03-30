#ifndef WHATSAPP_H
#define WHATSAPP_H

#include <QObject>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QStringList>
#include <QtDBus/QtDBus>
#include <QTimer>

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
    Q_OBJECT

public:
    //friend class DBClient;
    WhatsApp(QObject *parent = 0);
    ~WhatsApp();

private:
    bool isActive();

    QNetworkAccessManager *nam;
    QString _pendingJid;

    QDBusInterface *iface;

    QTranslator translator;

    QTimer *pingServer;

signals:
    void ready();
    void activeChanged();
    void connectionStatusChanged(int connStatus);
    void messageReceived(const QVariantMap &data);
    void disconnected(const QString &reason);
    void authFail(const QString &username, const QString &reason);
    void authSuccess(const QString &username);
    void networkChanged(bool value);
    void noAccountData();
    void registered();
    void smsTimeout(int timeout);
    void registrationFailed(const QVariantMap &reason);
    void registrationComplete();
    void accountExpired(const QVariantMap &reason);
    void gotAccountData(const QString &username, const QString &password);
    void codeRequested(const QVariantMap &method);
    void existsRequestFailed(const QVariantMap &serverReply);
    void codeRequestFailed(const QVariantMap &serverReply);
    void messageStatusUpdated(const QString &mjid, const QString &msgId, int msgstatus);
    void pictureUpdated(const QString &pjid, const QString &path);
    void contactsChanged();
    void contactChanged(const QVariantMap &data);
    void contactSynced(const QVariantMap &data);
    void newGroupSubject(const QVariantMap &data);
    void notificationOpenJid(const QString &njid);
    void setUnread(const QString &jid, int count);
    void pushnameUpdated(const QString &mjid, const QString &pushName);
    void presenceAvailable(const QString &mjid);
    void presenceUnavailable(const QString &mjid);
    void presenceLastSeen(const QString &mjid, int seconds);
    void mediaDownloadProgress(const QString &mjid, const QString &msgId, int progress);
    void mediaDownloadFinished(const QString &mjid, const QString &msgId, const QString &path);
    void mediaDownloadFailed(const QString &mjid, const QString &msgId);
    void groupParticipant(const QString &gjid, const QString &pjid);
    void groupInfo(const QVariantMap &group);
    void groupCreated(const QString &gjid);
    void participantAdded(const QString &gjid, const QString &pjid);
    void participantRemoved(const QString &gjid, const QString &pjid);
    void contactsBlocked(const QStringList &list);
    void activeJidChanged(const QString &ajid);
    void contactTyping(const QString &cjid);
    void contactPaused(const QString &cjid);
    void synchronizationFinished();
    void synchronizationFailed();
    void phonebookReceived(const QVariantList &contactsmodel);
    void uploadMediaFailed(const QString &mjid, const QString &msgId);
    void groupsMuted(const QStringList &jids);
    void codeReceived();
    void dissectError();

    void replyCrashed(bool isCrashed);
    void myAccount(const QString &account);

    void logfileReady(const QByteArray &data, bool isReady);

private slots:
    void onReplyCrashed(QDBusPendingCallWatcher *call);
    void onMyAccount(QDBusPendingCallWatcher *call);
    void doPingServer();
    void onServerPong();

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
    void downloadMedia(const QString &msgId, const QString &jid);
    void cancelDownload(const QString &msgId, const QString &jid);
    void abortMediaDownload(const QString &msgId, const QString &jid);
    void openVCardData(const QString &name, const QString &data);
    void getParticipants(const QString &jid);
    void getGroupInfo(const QString &jid);
    void regRequest(const QString &phone, const QString &method, const QString &password);
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
    void isCrashed();
    void requestLastOnline(const QString &jid);
    void addPhoneNumber(const QString &name, const QString &phone);
    void sendMedia(const QStringList &jids, const QString &path);
    void sendVCard(const QStringList &jids, const QString &name, const QString& data);
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
    void sendLocation(const QStringList &jids, const QString &latitude, const QString &longitude, int zoom, bool googlemaps = false);
    void renewAccount();
};

#endif // WHATSAPP_H
