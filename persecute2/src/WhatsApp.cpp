#include "WhatsApp.h"
#include <QFile>
#include <QTextStream>
#include <QCryptographicHash>
#include <QDebug>
//#include <QtCrypto/qca.h>
#include <QDateTime>
#include <QDesktopServices>
#include <QImage>
#include <QTransform>
#include <QGuiApplication>
#include <QClipboard>
#include "constants.h"

#define OBJECT_NAME "/"
#define SERVICE_NAME "com.whatsapp.client"

bool lessThan(const QVariant &v1, const QVariant &v2) {
    return v1.toMap()["nickname"].toString().toLower() < v2.toMap()["nickname"].toString().toLower();
}

WhatsApp::WhatsApp(QObject *parent): QObject(parent)
{
    nam = new QNetworkAccessManager(this);
    _active = false;
    _online = true;
    _network = false;
    _pendingJid = QString();

    qDebug() << "Connecting to DBus signals";
    iface = new QDBusInterface(SERVER_SERVICE,
                               SERVER_PATH,
                               SERVER_INTERFACE,
                               QDBusConnection::sessionBus(),
                               this);
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageReceived", this, SIGNAL(messageReceived(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "disconnected", this, SIGNAL(disconnected(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "authFail", this, SIGNAL(authFail(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "authSuccess", this, SIGNAL(authSuccess(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "networkAvailable", this, SIGNAL(networkChanged(bool)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "noAccountData", this, SIGNAL(noAccountData()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageStatusUpdated", this, SIGNAL(messageStatusUpdated(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "pictureUpdated", this, SIGNAL(pictureUpdated(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactsChanged", this, SIGNAL(contactsChanged()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "notificationOpenJid", this, SIGNAL(notificationOpenJid(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "setUnread", this, SIGNAL(setUnread(QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "myAccount", this, SIGNAL(myAccount(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "pushnameUpdated", this, SIGNAL(pushnameUpdated(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactAvailable", this, SIGNAL(presenceAvailable(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactUnavailable", this, SIGNAL(presenceUnavailable(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactLastSeen", this, SIGNAL(presenceLastSeen(QString, int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactChanged", this, SIGNAL(contactChanged(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactSynced", this, SIGNAL(contactSynced(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "newGroupSubject", this, SIGNAL(newGroupSubject(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadProgress", this, SIGNAL(mediaDownloadProgress(QString, QString, )));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "mediaDownloadFinished", this, SIGNAL(mediaDownloadFinished(QString, QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadFailed", this, SIGNAL(mediaDownloadFailed(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "connectionStatusChanged", this, SIGNAL(connectionStatusChanged(int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupParticipant", this, SIGNAL(groupParticipant(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupInfo", this, SIGNAL(groupInfo(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "registered", this, SIGNAL(registered()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "smsTimeout", this, SIGNAL(smsTimeout(int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "registrationFailed", this, SIGNAL(registrationFailed(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "existsRequestFailed", this, SIGNAL(existsRequestFailed(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "registrationComplete", this, SIGNAL(registrationComplete()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "codeRequestFailed", this, SIGNAL(codeRequestFailed(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "codeRequested", this, SIGNAL(codeRequested(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "accountExpired", this, SIGNAL(accountExpired(QVariantMap)));;
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupCreated", this, SIGNAL(groupCreated(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupParticipantAdded", this, SIGNAL(participantAdded(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupParticipantRemoved", this, SIGNAL(participantRemoved(QString, QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactsBlocked", this, SIGNAL(contactsBlocked(QStringList)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactTyping", this, SIGNAL(contactTyping(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "contactPaused", this, SIGNAL(contactPaused(QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "synchronizationFinished", this, SIGNAL(synchronizationFinished()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "synchronizationFailed", this, SIGNAL(synchronizationFailed()));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadFailed", this, SIGNAL(uploadMediaFailed(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "groupsMuted", this, SIGNAL(groupsMuted(QStringList)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "codeReceived", this, SIGNAL(codeReceived()));
    //QDBusReply<int> reply = iface->call(QDBus::AutoDetect, "currentStatus");
    //_online = reply.value() == 3;

    Q_EMIT ready();
}

WhatsApp::~WhatsApp()
{
    setPresenceUnavailable();
    if (nam)
        delete nam;
    if (iface) {
        delete iface;
    }
}

int WhatsApp::connectionStatus()
{
    if (iface) {
        QDBusReply<int> reply = iface->call(QDBus::AutoDetect, "currentStatus");
        //qDebug() << "connectionStatus:" << reply.value();
        return reply.value();
    }
    return 0;
}

void WhatsApp::authenticate()
{
    if (iface)
        iface->call(QDBus::NoBlock, "recheckAccountAndConnect");
}

void WhatsApp::init()
{
    if (iface)
        iface->call(QDBus::NoBlock, "init");
}

void WhatsApp::disconnect()
{
    if (iface)
        iface->call(QDBus::NoBlock, "disconnect");
}

void WhatsApp::sendMessage(const QString &jid, const QString &message, const QString &media, const QString &mediaData)
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendMessage", jid, message, media, mediaData);
}

void WhatsApp::sendBroadcast(const QStringList &jids, const QString &message)
{
    if (iface)
        iface->call(QDBus::NoBlock, "broadcastSend", jids, message);
}

void WhatsApp::sendText(const QString &jid, const QString &message)
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendText", jid, message);
}

void WhatsApp::syncContactList()
{
    if (iface)
        iface->call(QDBus::NoBlock, "synchronizeContacts");
}

void WhatsApp::setActiveJid(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setActiveJid", jid);
    Q_EMIT activeJidChanged(jid);
}

QString WhatsApp::shouldOpenJid()
{
    return _pendingJid;
}

QString WhatsApp::getMyAccount()
{
    if (iface) {
        QDBusReply<QString> reply = iface->call(QDBus::AutoDetect, "getMyAccount");
        //qDebug() << "my account:" << reply.value();
        return reply.value();
    }
    return QString();
}

void WhatsApp::startTyping(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "startTyping", jid);
}

void WhatsApp::endTyping(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "endTyping", jid);
}

bool WhatsApp::getAvailable(const QString &jid)
{
    if (iface) {
        QDBusReply<bool> reply = iface->call(QDBus::AutoDetect, "getAvailable", jid);
        //qDebug() << "Get" << jid << "available from server:" << reply.value();
        return reply.value();
    }
    return false;
}

void WhatsApp::downloadMedia(const QString &msgId, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "downloadMedia", msgId, jid);
}

void WhatsApp::cancelDownload(const QString &msgId, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "cancelDownload", msgId, jid);
}

void WhatsApp::abortMediaDownload(const QString &msgId, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "cancelDownload", msgId, jid);
}

void WhatsApp::openVCardData(const QString &name, const QString &data)
{
    QString path = QString("/var/tmp/%1.vcf").arg(name);
    QFile file(path);
    if (file.exists())
        file.remove();
    if (file.open(QFile::WriteOnly | QFile::Text)) {
        file.write(data.toUtf8());
        file.close();
    }
    QDesktopServices::openUrl(QUrl(path));
}

void WhatsApp::getParticipants(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "getParticipants", jid);
}

void WhatsApp::getGroupInfo(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "getGroupInfo", jid);
}

void WhatsApp::regRequest(const QString &phone, const QString &method)
{
    if (iface)
        iface->call(QDBus::NoBlock, "regRequest", phone, method);
}

void WhatsApp::enterCode(const QString &phone, const QString &code)
{
    if (iface)
        iface->call(QDBus::NoBlock, "enterCode", phone, code);
}

void WhatsApp::setGroupSubject(const QString &gjid, const QString &subject)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setGroupSubject", gjid, subject);
}

void WhatsApp::createGroup(const QString &subject)
{
    if (iface)
        iface->call(QDBus::NoBlock, "createGroupChat", subject);
}

void WhatsApp::groupLeave(const QString &gjid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "requestLeaveGroup", gjid);
}

void WhatsApp::setPicture(const QString &jid, const QString &path)
{
    if (iface)
        iface->call(QDBus::NoBlock, "setPicture", jid, path);
}

void WhatsApp::removeParticipant(const QString &gjid, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "removeGroupParticipant", gjid, jid);
}

void WhatsApp::addParticipant(const QString &gjid, const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "addGroupParticipant", gjid, jid);
}

void WhatsApp::refreshContact(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "refreshContact", jid);
}

QString WhatsApp::transformPicture(const QString &filename, const QString &jid, int posX, int posY, int sizeW, int sizeH, int maxSize, int rotation)
{
    qDebug() << "Preparing picture" << filename << "- rotation:" << QString::number(rotation);
    QString image = filename;
    image = image.replace("file://","");

    QImage preimg(image);

    if (sizeW == sizeH) {
        preimg = preimg.copy(posX,posY,sizeW,sizeH);
        if (sizeW > maxSize)
            preimg = preimg.scaledToWidth(maxSize, Qt::SmoothTransformation);
    }
    if (rotation != 0) {
        QTransform rot;
        rot.rotate(rotation);
        preimg = preimg.transformed(rot);
    }
    if (sizeW != sizeH) {
        preimg = preimg.copy(posX,posY,sizeW,sizeH);
        if (sizeW > maxSize)
            preimg = preimg.scaledToWidth(maxSize, Qt::SmoothTransformation);
    }
    QString path = QString("/tmp/%1-%2").arg(jid).arg(QString::number(QDateTime::currentDateTime().toTime_t()));
    qDebug() << "Saving to:" << path << (preimg.save(path, "JPG") ? "success" : "error");

    return path;
}

void WhatsApp::copyToClipboard(const QString &text)
{
    QClipboard *clip = QGuiApplication::clipboard();
    clip->setText(text);
}

void WhatsApp::blockOrUnblockContact(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "blockOrUnblockContact", jid);
}

void WhatsApp::sendBlockedJids(const QStringList &jids)
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendBlockedJids", jids);
}

void WhatsApp::muteOrUnmuteGroup(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "muteOrUnmuteGroup", jid);
}

void WhatsApp::muteGroups(const QStringList &jids)
{
    if (iface)
        iface->call(QDBus::NoBlock, "muteGroups", jids);
}

void WhatsApp::getPrivacyList()
{
    if (iface)
        iface->call(QDBus::NoBlock, "getPrivacyList");
}

void WhatsApp::getMutedGroups()
{
    if (iface)
        iface->call(QDBus::NoBlock, "getMutedGroups");
}

void WhatsApp::forwardMessage(const QStringList &jids, const QString &jid, const QString &msgid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "forwardMessage", jids, jid, msgid);
}

void WhatsApp::setMyPushname(const QString &pushname)
{
    if (iface)
        iface->call(QDBus::NoBlock, "changeUserName", pushname);
}

void WhatsApp::setMyPresence(const QString &presence)
{
    if (iface)
        iface->call(QDBus::NoBlock, "changeStatus", presence);
}

void WhatsApp::sendRecentLogs()
{
    if (iface)
        iface->call(QDBus::NoBlock, "sendRecentLogs");
}

void WhatsApp::shutdown()
{
    if (iface)
        iface->call(QDBus::NoBlock, "exit");
    exit();
}

bool WhatsApp::isCrashed()
{
    if (iface) {
        QDBusReply<bool> reply = iface->call(QDBus::AutoDetect, "isCrashed");
        return reply.value();
    }
    return false;
}

void WhatsApp::requestLastOnline(const QString &jid)
{
    if (iface)
        iface->call(QDBus::NoBlock, "requestQueryLastOnline", jid);
}

void WhatsApp::addPhoneNumber(const QString &name, const QString &phone)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "newContactAdd", name, phone);
    }
}

QStringList WhatsApp::getDownloads()
{
    if (iface) {
        QDBusReply<QStringList> reply = iface->call(QDBus::AutoDetect, "getDownloads");
        if (reply.isValid()) {
            return reply.value();
        }
    }
    return QStringList();
}

bool WhatsApp::isActive()
{
    return _active;
}

bool WhatsApp::isOnline()
{
    //QDBusReply<int> reply = iface->call(QDBus::AutoDetect, "currentStatus");
    //_online = reply.value() == 4;
    return true;
}

bool WhatsApp::isNetwork()
{
    QDBusReply<bool> reply = iface->call(QDBus::AutoDetect, "isNetworkAvailable");
    _network = reply.value();
    return _network;
}

void WhatsApp::exit()
{
    qDebug() << "Remote command requested exit";
    QGuiApplication::exit(0);
}

void WhatsApp::setPendingJid(const QString &jid)
{
    _pendingJid = jid;
    Q_EMIT notificationOpenJid(jid);
}


void WhatsApp::sendMedia(const QStringList &jids, const QString &path)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "sendMedia", jids, path);
    }
}

QString WhatsApp::rotateImage(const QString &path, int rotation)
{
    QString fname = path;
    fname = fname.replace("file://", "");
    if (QFile(fname).exists()) {
        qDebug() << "rotateImage" << fname << QString::number(rotation);
        QImage img(fname);
        QTransform rot;
        rot.rotate(rotation);
        img = img.transformed(rot);
        fname = fname.split("/").last();
        fname = QString("/tmp/%1-%2").arg(QDateTime::currentDateTime().toTime_t()).arg(fname);
        qDebug() << "destination:" << fname;
        if (img.save(fname))
            return fname;
        else
            return QString();
    }
    return QString();
}

QString WhatsApp::saveImage(const QString &path)
{
    if (!path.startsWith("/home/nemo/Pictures")) {
        QFile img(path);
        if (img.exists()) {
            qDebug() << "saveImage" << path;
            QString name = path.split("/").last().split("@").first();
            QString destination = QString("/home/nemo/Pictures/%1").arg(name);
            img.copy(path, destination);
            qDebug() << "destination:" << destination;
            return name;
        }
    }
    return QString();
}

void WhatsApp::openProfile(const QString &name, const QString &phone, const QString avatar)
{
    QFile tmp("/tmp/_persecute-"+phone);
    if (tmp.open(QFile::WriteOnly | QFile::Text)) {
        QTextStream out(&tmp);
        out << "BEGIN:VCARD\n";
        out << "VERSION:3.0\n";
        out << "FN:" << name << "\n";
        out << "N:" << name << "\n";
        out << "TEL:" << phone << "\n";
        if (!avatar.isEmpty()) {

        }
        out << "END:VCARD";
        tmp.close();

        QDesktopServices::openUrl(tmp.fileName());
    }
}

void WhatsApp::removeAccount()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "removeAccount");
    }
}

void WhatsApp::tryGetWazappAcc()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "tryGetWazappAcc");
    }
}

void WhatsApp::tryGetWhatsupAcc()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "tryGetWhatsupAcc");
    }
}

void WhatsApp::getPhonebook()
{
    QContactManager *manager = new QContactManager(this);
    QList<QContact> results = manager->contacts();
    QVariantList contacts;
    QStringList phones;
    qDebug() << "Have" << QString::number(results.size()) << "contacts";
    for (int i = 0; i < results.size(); ++i) {
        QString avatar;
        QList<QContactAvatar> avatars = results.at(i).details<QContactAvatar>();
        QList<QContactDisplayLabel> labels = results.at(i).details<QContactDisplayLabel>();
        QString label;
        if (labels.size() > 0 && !labels.first().isEmpty())
            label = labels.first().label();
        if (avatars.length() > 0 && !avatars.first().isEmpty())
            avatar = avatars.first().imageUrl().toString();
        foreach (QContactPhoneNumber number, results.at(i).details<QContactPhoneNumber>()) {
            if (!number.isEmpty()) {
                QVariantMap contact;
                QString phone = number.number();
                phone = phone.replace(QRegExp("/[^0-9+]/g"),"");
                if (!phones.contains(phone)) {
                    phones.append(phone);
                    contact["avatar"] = avatar;
                    contact["nickname"] = label.isEmpty() ? phone : label;
                    contact["number"] = phone;
                    contacts.append(contact);
                    qDebug() << label << phone;
                }
            }
        }
    }
    qSort(contacts.begin(), contacts.end(), lessThan);

    Q_EMIT phonebookReceived(contacts);

    manager->deleteLater();
}

void WhatsApp::syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "syncContacts", numbers, names, avatars);
    }
}

void WhatsApp::setPresenceAvailable()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "setPresenceAvailable");
    }
}

void WhatsApp::setPresenceUnavailable()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "setPresenceUnavailable");
    }
}

void WhatsApp::syncAllPhonebook()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "synchronizePhonebook");
    }
}

void WhatsApp::removeAccountFromServer()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "removeAccountFromServer");
    }
}

void WhatsApp::forceConnection()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "forceConnection");
    }
}

void WhatsApp::setLocale(const QString &localeName)
{
    QGuiApplication::removeTranslator(&translator);

    QString locale = localeName.split(".").first();

    qDebug() << "Loading translation:" << locale;
    qDebug() << (translator.load(locale, "/usr/share/harbour-mitakuuluu/locales", QString(), ".qm") ? "Translator loaded" : "Error loading translator");
    qDebug() << (QGuiApplication::installTranslator(&translator) ? "Translator installed" : "Error installing translator");
}

int WhatsApp::getExifRotation(const QString &image)
{
    if ((image.toLower().endsWith("jpg") || image.toLower().endsWith("jpeg")) && QFile(image).exists()) {
        ExifData *ed;
        ed = exif_data_new_from_file(image.toLocal8Bit().data());
        if (!ed) {
            qDebug() << "File not readable or no EXIF data in file" << image;
        }
        else {
            ExifEntry *entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_ORIENTATION);
            if (entry) {
                char buf[1024];

                /* Get the contents of the tag in human-readable form */
                exif_entry_get_value(entry, buf, sizeof(buf));

                int rotation = 0;

                QString value = QString(buf).toLower();
                //qDebug() << value << image;

                if (value == "right-top")
                    rotation = 90;
                else
                    rotation = 0;

                return rotation;
            }
        }
    }
    return 0;
}

void WhatsApp::windowActive()
{
    if (iface) {
        iface->call(QDBus::NoBlock, "windowActive");
    }
}
