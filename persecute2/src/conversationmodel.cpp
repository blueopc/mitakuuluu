#include "conversationmodel.h"
#include "constants.h"

#include <QGuiApplication>
#include <QClipboard>

#include <QUuid>
#include <QDateTime>

ConversationModel::ConversationModel(QObject *parent) :
    QAbstractListModel(parent)
{
    _roles[JidRole] = "jid";
    _roles[MessageidRole] = "msgid";
    _roles[TimestampRole] = "timestamp";
    _roles[AuthorRole] = "author";
    _roles[MessageRole] = "message";
    _roles[MessagetypeRole] = "msgtype";
    _roles[MessagestatusRole] = "msgstatus";
    _roles[MediatypeRole] = "mediatype";
    _roles[MediaurlRole] = "mediaurl";
    _roles[MediaLatitudeRole] = "medialat";
    _roles[MediaLongitudeRole] = "medialon";
    _roles[MediaSizeRole] = "mediasize";
    _roles[MediaPreviewRole] = "mediathumb";
    _roles[MediaMimeRole] = "mediamime";
    _roles[MediaDurationRole] = "mediaduration";
    _roles[MediaLocalUrlRole] = "localurl";
    _roles[BroadcastRole] = "broadcast";
    _roles[MediaprogressRole] = "mediaprogress";
    _roles[SectionRole] = "msgdate";
    //setRoleNames(_roles);

    uuid = QUuid::createUuid().toString();

    dbExecutor = QueryExecutor::GetInstance();
    connect(dbExecutor, SIGNAL(actionDone(QVariant)), this, SLOT(dbResults(QVariant)));

    iface = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageReceived", this, SLOT(onMessageReceived(QVariantMap)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "messageStatusUpdated", this, SLOT(onMessageStatusUpdated(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadProgress", this, SLOT(onMediaProgress(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadFinished", this, SLOT(onMediaFinished(QString,QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "downloadFailed", this, SLOT(onMediaFailed(QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadProgress", this, SLOT(onMediaProgress(QString,QString,int)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploaddFinished", this, SLOT(onMediaFinished(QString,QString,QString)));
    QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                          "uploadFailed", this, SLOT(onMediaFailed(QString,QString)));
}

ConversationModel::~ConversationModel()
{
    if (iface)
        delete iface;
}

void ConversationModel::loadLastConversation(QString newjid)
{
    _loadingBusy = true;
    qDebug() << "load last conversation for:" << newjid;
    QDBusReply<QVariantMap> reply = iface->call(QDBus::AutoDetect, "getDownloads");
    if (reply.isValid())
        _downloadData = reply.value();
    jid = newjid;
    table = jid.split("@").first().replace("-", "g");
    QVariantMap query;
    query["type"] = QueryType::ConversationLoadLast;
    query["table"] = table;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

int ConversationModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.count();
}

QVariant ConversationModel::data(const QModelIndex &index, int role) const
{
    int row = index.row();
    if (row < 0 || row >= _modelData.count())
        return QVariant();
    QString msgId = _sortedTimestampMsgidList.at(row)._msgid;
    if (role == MediaLocalUrlRole)
        return _modelData[msgId]["localurl"].toString();
    QVariant value = _modelData[msgId][_roles[role]];
    return value;
}

void ConversationModel::setPropertyByMsgId(const QString &msgId, const QString &name, const QVariant &value)
{
    if (_modelData.keys().contains(msgId)) {
        _modelData[msgId][name] = value;
        int row = getIndexByMsgId(msgId);
        Q_EMIT dataChanged(index(row), index(row));
    }
}

void ConversationModel::loadOldConversation(int count)
{
    if (_modelData.isEmpty())
        return;
    if (_loadingBusy)
        return;
    _loadingBusy = true;
    qDebug() << "load old converstaion for:" << jid;
    int stamp = _sortedTimestampMsgidList.first()._timestamp;

    QVariantMap query;
    query["type"] = QueryType::ConversationLoadNext;
    query["table"] = table;
    query["timestamp"] = stamp;
    query["count"] = count;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ConversationModel::deleteMessage(const QString &msgId, bool deleteMediaFiles)
{
    if (!_modelData.keys().contains(msgId))
        return;

    if (deleteMediaFiles && iface) {
        QDBusReply<QString> reply = iface->call(QDBus::AutoDetect, "getMyAccount");
        //qDebug() << "my account:" << reply.value();
        QString myJid = reply.value();
        QString author = _modelData[msgId]["author"].toString();
        QString localurl = _modelData[msgId]["localurl"].toString();
        if (localurl.startsWith("/tmp") || (author != myJid)) {
            QFile media(localurl);
            if (media.exists()) {
                media.remove();
            }
        }
    }

    int rowIndex = getIndexByMsgId(msgId);
    beginRemoveRows(QModelIndex(), rowIndex, rowIndex);
    _modelData.remove(msgId);
    _sortedTimestampMsgidList.removeAt(rowIndex);
    endRemoveRows();

    QVariantMap query;
    query["type"] = QueryType::ConversationRemoveMessage;
    query["table"] = table;
    query["msgid"] = msgId;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

QVariantMap ConversationModel::get(int index)
{
    if (index < 0 || index >= _modelData.size())
        return QVariantMap();
    QString msgId = _sortedTimestampMsgidList.at(index)._msgid;
    return _modelData[msgId];
}

QVariantMap ConversationModel::getModelByIndex(int index)
{
    if (index < 0 || index >= _modelData.size())
        return QVariantMap();
    QString msgId = _sortedTimestampMsgidList.at(index)._msgid;
    QVariantMap data = _modelData[msgId];
    return data;
}

QVariantMap ConversationModel::getModelByMsgId(const QString &msgId)
{
    if (_modelData.keys().contains(msgId))
        return _modelData[msgId];
    return QVariantMap();
}

void ConversationModel::copyToClipboard(const QString &msgId)
{
    if (!_modelData.keys().contains(msgId))
        return;
    QString text;
    QVariantMap data = _modelData[msgId];
    int msgtype = data["msgtype"].toInt();
    if (msgtype == 2) {
        text = data["message"].toString();
    }
    else if (msgtype == 3) {
        int mediatype = data["mediatype"].toInt();
        if (mediatype > 0 && mediatype < 4) {
            QString url = data["mediaurl"].toString();
            text = url;
        }
        else if (mediatype == 5) {
            QString latitude = data["medialat"].toString();
            QString longitude = data["medialon"].toString();
            QString url = QString("https://maps.google.com/maps?q=loc:%1,%2").arg(latitude).arg(longitude);
            text = url;
        }
    }
    if (!text.isEmpty()) {
        QGuiApplication::clipboard()->setText(text);
    }
}

void ConversationModel::forwardMessage(const QStringList &jids, const QString &msgId)
{
    if (iface) {
        QVariantMap model = getModelByMsgId(msgId);
        //qDebug() << "model";
        //qDebug() << model;
        iface->call(QDBus::NoBlock, "forwardMessage", jids, model);
    }
}

void ConversationModel::removeConversation(const QString &rjid)
{
    if (jid == rjid) {
        beginResetModel();
        Q_EMIT lastMessageToBeChanged(rjid);
        _modelData.clear();
        _sortedTimestampMsgidList.clear();
        endResetModel();
        Q_EMIT lastMessageChanged(rjid, true);
    }
    QVariantMap query;
    query["type"] = QueryType::ConversationRemoveAll;
    query["jid"] = rjid;
    query["table"] = table;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

int ConversationModel::count()
{
    return _modelData.size();
}

void ConversationModel::saveHistory(const QString &sjid, const QString &sname)
{
    QVariantMap query;
    query["type"] = QueryType::ConversationSave;
    query["name"] = sname;
    query["jid"] = sjid;
    query["table"] = sjid.split("@").first().replace("-", "g");;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

int ConversationModel::getIndexByMsgId(const QString &msgId)
{
    if (!_modelData.keys().contains(msgId))
        return -1;
    for (int i = 0; i < _sortedTimestampMsgidList.count(); i++) {
        if (_sortedTimestampMsgidList.at(i)._msgid == msgId)
            return i;
    }
    return -1;
}

QString ConversationModel::makeTimestampDate(int timestamp)
{
    return QDateTime::fromTime_t(timestamp).toString("dd MMM yyyy");
}

void ConversationModel::onLoadingFree()
{
    _loadingBusy = false;
}

void ConversationModel::onMessageReceived(const QVariantMap &data)
{
    //qDebug() << data;
    //qDebug() << "messageReceived: " << data["jid"] << data["message"];
    if (data["jid"].toString() == jid) {
        QVariantMap message = data;
        message["mediaprogress"] = 0;
        QString msgId = message["msgid"].toString();
        int timestamp = message["timestamp"].toInt();

        if (!_modelData.contains(msgId)) {
            Q_EMIT lastMessageToBeChanged(jid);
            beginInsertRows(QModelIndex(), _modelData.count(), _modelData.count());
            _modelData[msgId] = message;
            _modelData[msgId]["msgdate"] = makeTimestampDate(timestamp);
            _sortedTimestampMsgidList.append(TimestampMsgidPair(timestamp, msgId));
            //qSort(_sortedTimestampMsgidList); //is it necessary?
            endInsertRows();
            Q_EMIT lastMessageChanged(jid, false);
        }
        else {
            int row = getIndexByMsgId(msgId);
            _modelData[msgId] = message;
            _modelData[msgId]["msgdate"] = makeTimestampDate(timestamp);
            dataChanged(index(row), index(row));
        }
    }
}

void ConversationModel::onMessageStatusUpdated(const QString &mjid, const QString &msgId, int msgstatus)
{
    if (mjid == jid) {
        qDebug() << "Update message status for:" << msgId << "status:" << QString::number(msgstatus);
        setPropertyByMsgId(msgId, "msgstatus", msgstatus);
    }
}

void ConversationModel::onMediaProgress(const QString &mjid, const QString &msgId, int progress)
{
    qDebug() << "Media download progress" << mjid << msgId << QString::number(progress);
    if (mjid == jid) {
        setPropertyByMsgId(msgId, "mediaprogress", progress);
    }
}

void ConversationModel::onMediaFinished(const QString &mjid, const QString &msgId, const QString &path)
{
    if (mjid == jid) {
        //setPropertyByMsgId(msgId, "mediatype", 12);
        //setPropertyByMsgId(msgId, "message", QString("%1,%2").arg(_modelData[msgId]["message"].toString()).arg(path));
        //setPropertyByMsgId(msgId, "mediaprogress", 0);
    }
}

void ConversationModel::onMediaFailed(const QString &mjid, const QString &msgId)
{
    if (mjid == jid) {
        deleteMessage(msgId);
    }
}

void ConversationModel::dbResults(const QVariant &result)
{
    QVariantMap reply = result.toMap();
    if (reply["uuid"].toString() != uuid)
        return;
    int vtype = reply["type"].toInt();
    switch (vtype) {
    case QueryType::ConversationLoadLast: {
        beginResetModel();
        _modelData.clear();
        _sortedTimestampMsgidList.clear();
        //endResetModel();

        Q_EMIT lastMessageToBeChanged(jid);
        QVariantList records = reply["messages"].toList();
        if (records.size() > 0) {
            //beginInsertRows(QModelIndex(), 0, records.size() - 1);
            foreach (const QVariant &c, records) {
                QVariantMap data = c.toMap();
                QString msgId = data["msgid"].toString();
                int timestamp = data["timestamp"].toInt();
                data["localurl"] = QString::fromUtf8(data["localurl"].toByteArray());
                data["mediaprogress"] = _downloadData.contains(msgId) ? _downloadData[msgId] : 0;
                data["msgdate"] = makeTimestampDate(timestamp);
                if (!_modelData.keys().contains(msgId)) {
                    //qDebug() << data["message"].toString();
                    _modelData[msgId] = data;
                    _sortedTimestampMsgidList.append(TimestampMsgidPair(timestamp, msgId));
                }
            }
            qSort(_sortedTimestampMsgidList);
            //endInsertRows();
        }
        endResetModel();
        _loadingBusy = false;
        Q_EMIT lastMessageChanged(jid, true);
        break;
    }
    case QueryType::ConversationLoadNext: {
        QVariantList records = reply["messages"].toList();
        if (records.size() > 0) {
            beginInsertRows(QModelIndex(), 0, records.size() - 1);
            foreach (const QVariant &c, records) {
                QVariantMap data = c.toMap();
                QString msgId = data["msgid"].toString();
                int timestamp = data["timestamp"].toInt();
                data["mediaprogress"] = _downloadData.contains(msgId) ? _downloadData[msgId] : 0;
                data["msgdate"] = makeTimestampDate(timestamp);
                if (!_modelData.keys().contains(msgId)) {
                    _modelData[msgId] = data;
                    _sortedTimestampMsgidList.append(TimestampMsgidPair(timestamp, msgId));
                }
            }
            qSort(_sortedTimestampMsgidList);
            endInsertRows();
        }
        _loadingBusy = false;
        Q_EMIT lastMessageChanged(jid, false);
        break;
    }
    default: {
        break;
    }
    }
}
