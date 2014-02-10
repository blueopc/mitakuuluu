#include "contactsmodel.h"
#include "constants.h"
#include <QDebug>
#include <cmath>

#include <QUuid>

ContactsModel::ContactsModel(QObject *parent) :
    QAbstractListModel(parent)
{
    _roles[JidRole] = "jid";
    _roles[PushnameRole] = "pushname";
    _roles[NameRole] = "name";
    _roles[NicknameRole] = "nickname";
    _roles[StatusRole] = "message";
    _roles[ContacttypeRole] = "contacttype";
    _roles[GroupOwnerRole] = "owner";
    _roles[GroupMessageOwnerRole] = "subowner";
    _roles[TimestampRole] = "timestamp";
    _roles[MessageTimestampRole] = "subtimestamp";
    _roles[AvatarRole] = "avatar";
    _roles[UnreadCountRole] = "unread";
    _roles[AvailableRole] = "available";
    _roles[LastMessageStampRole] = "lastmessage";
    _roles[BlockedRole] = "blocked";
    _roles[VisibleRole] = "visible";
    //setRoleNames(_roles);

    _filtering = false;
    _filter = QString();

    uuid = QUuid::createUuid().toString();

    _notify = false;
    iface = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);

    dbExecutor = QueryExecutor::GetInstance();
    connect(dbExecutor, SIGNAL(actionDone(QVariant)), this, SLOT(dbResults(QVariant)));
}

ContactsModel::~ContactsModel()
{
    if (iface) {
        delete iface;
    }
}

void ContactsModel::reloadContact(const QString &jid)
{
    QVariantMap query;
    query["type"] = QueryType::ContactsReloadContact;
    query["jid"] = jid;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

void ContactsModel::setPropertyByJid(const QString &jid, const QString &name, const QVariant &value)
{
    if (_modelData.keys().contains(jid)) {
        //qDebug() << "Model setPropertyByJid:" << jid << name << value;
        int row = getIndexByJid(jid);
        if (row > -1) {
            if (name == "avatar") {
                _modelData[jid][name] = QString();
                Q_EMIT dataChanged(index(row), index(row));
            }
            _modelData[jid][name] = value;
            Q_EMIT dataChanged(index(row), index(row));
        }

        if (name == "unread")
            checkTotalUnread();
    }
}

void ContactsModel::deleteContact(const QString &jid)
{
    int rowIndex = getIndexByJid(jid);
    if (rowIndex > -1) {
        beginRemoveRows(QModelIndex(), rowIndex, rowIndex);
        _modelData.remove(jid);
        QVariantMap query;
        query["type"] = QueryType::ContactsRemove;
        query["jid"]  = jid;
        query["uuid"] = uuid;
        dbExecutor->queueAction(query);
        _sortedJidNameList.removeAt(rowIndex);
        endRemoveRows();

        iface->call(QDBus::NoBlock, "contactRemoved", jid);
    }
}

QVariantMap ContactsModel::getModel(const QString &jid)
{
    if (_modelData.keys().contains(jid))
        return _modelData[jid];
    return QVariantMap();
}

QVariantMap ContactsModel::get(int index)
{
    if (index < 0 || index >= _modelData.count())
        return QVariantMap();
    QString jid = _sortedJidNameList.at(index)._jid;
    return _modelData[jid];
}

QColor ContactsModel::getColorForJid(const QString &jid)
{
    if (!_colors.keys().contains(jid))
        _colors[jid] = generateColor();
    QColor color = _colors[jid];
    color.setAlpha(96);
    return color;
}

void ContactsModel::clear()
{
    beginResetModel();
    _modelData.clear();
    _sortedJidNameList.clear();
    endResetModel();
    //reset();
}

QColor ContactsModel::generateColor()
{
    qreal golden_ratio_conjugate = 0.618033988749895;
    qreal h = (qreal)rand()/(qreal)RAND_MAX;
    h += golden_ratio_conjugate;
    h = fmod(h, 1);
    QColor color = QColor::fromHsvF(h, 0.5, 0.95);
    return color;
}

bool ContactsModel::getNotify()
{
    return _notify;
}

void ContactsModel::setNotify(bool value)
{
    if (value) {
        qDebug() << "ContactList connect to events";

        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pictureUpdated", this, SLOT(pictureUpdated(QString,QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "setUnread", this, SLOT(setUnread(QString,int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pushnameUpdated", this, SLOT(pushnameUpdated(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactAvailable", this, SLOT(presenceAvailable(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactUnavailable", this, SLOT(presenceUnavailable(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactLastSeen", this, SLOT(presenceLastSeen(QString, int)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactChanged", this, SLOT(contactChanged(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactSynced", this, SLOT(contactSynced(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsChanged", this, SLOT(contactsChanged()));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "newGroupSubject", this, SLOT(newGroupSubject(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "messageReceived", this, SLOT(messageReceived(QVariantMap)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactStatus", this, SLOT(contactStatus(QString, QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "activeJidChanged", this, SLOT(onActiveJidChanged(QString)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsBlocked", this, SLOT(contactsBlocked(QStringList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupsMuted", this, SLOT(groupsMuted(QStringList)));
        QDBusConnection::sessionBus().connect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsAvailable", this, SLOT(contactsAvailable(QStringList)));
        if (iface) {
            iface->call(QDBus::NoBlock, "getPrivacyList");
            iface->call(QDBus::NoBlock, "getMutedGroups");
            iface->call(QDBus::NoBlock, "getAvailableJids");
        }
    }
    else {
        qDebug() << "ContactList disconnect events";

        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pictureUpdated", this, SLOT(pictureUpdated(QString,QString)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "setUnread", this, SLOT(setUnread(QString,int)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "pushnameUpdated", this, SLOT(pushnameUpdated(QString, QString)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactAvailable", this, SLOT(presenceAvailable(QString)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactUnavailable", this, SLOT(presenceUnavailable(QString)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactLastSeen", this, SLOT(presenceLastSeen(QString, int)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactChanged", this, SLOT(contactChanged(QVariantMap)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactSynced", this, SLOT(contactSynced(QVariantMap)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsChanged", this, SLOT(contactsChanged()));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "newGroupSubject", this, SLOT(newGroupSubject(QVariantMap)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "messageReceived", this, SLOT(messageReceived(QVariantMap)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactStatus", this, SLOT(contactStatus(QString, QString)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "activeJidChanged", this, SLOT(onActiveJidChanged(QString)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsBlocked", this, SLOT(contactsBlocked(QStringList)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "groupsMuted", this, SLOT(groupsMuted(QStringList)));
        QDBusConnection::sessionBus().disconnect(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE,
                                              "contactsAvailable", this, SLOT(contactsAvailable(QStringList)));
    }
    _notify = value;
}

int ContactsModel::getTotalUnread()
{
    return _totalUnread;
}

void ContactsModel::checkTotalUnread()
{
    _totalUnread = 0;
    foreach (const QVariantMap &contact, _modelData.values()) {
        //qDebug() << contact["jid"].toString() << "unread:" << contact["unread"].toInt();
        _totalUnread += contact["unread"].toInt();
    }
    //qDebug() << "Total unread:" << QString::number(_totalUnread);
    Q_EMIT totalUnreadChanged();
}

bool ContactsModel::getAvailable(const QString &jid)
{
    return _availableContacts.contains(jid);
}

bool ContactsModel::getBlocked(const QString &jid)
{
    return _blockedContacts.contains(jid);
}

bool ContactsModel::getMuted(QString jid)
{
    return _mutedGroups.contains(jid);
}

int ContactsModel::getIndexByJid(const QString &jid)
{
    if (_modelData.keys().contains(jid))
        return _modelData[jid]["modelindex"].toInt();
    return -1;
}

QString ContactsModel::getNicknameBy(const QString &jid, const QString &message, const QString &name, const QString &pushname)
{
    QString nickname;
    if (jid.contains("-")) {
        nickname = message;
    }
    else if (name == jid.split("@").first() || name.isEmpty()) {
        if (!pushname.isEmpty())
            nickname = pushname;
        else
            nickname = jid.split("@").first();
    }
    else {
        nickname = name;
    }
    return nickname;
}

void ContactsModel::pictureUpdated(const QString &jid, const QString &path)
{
    setPropertyByJid(jid, "avatar", path);
}

void ContactsModel::contactChanged(const QVariantMap &data)
{
    QVariantMap contact = data;
    QString jid = contact["jid"].toString();
    QString name = contact["name"].toString();
    QString message = contact["message"].toString();
    QString pushname = contact["pushname"].toString();
    QString nickname = getNicknameBy(jid, message, name, pushname);
    /*if (jid.contains("-")) {
        nickname = message;
    }
    else if (name == jid.split("@").first()) {
        if (!pushname.isEmpty())
            nickname = pushname;
        else
            nickname = name;
    }
    else {
        nickname = name;
    }*/
    contact["nickname"] = nickname;
    JidNameStampPair pair(jid, nickname, 0);
    if (_modelData.keys().contains(jid)) {
        pair._stamp = _modelData[jid]["lastmessage"].toInt();
        QString avatar = _modelData[jid]["avatar"].toString();
        contact["avatar"] = avatar;
        int row = getIndexByJid(jid);
        if (row > -1) {
            _sortedJidNameList[row] = pair;

            if (_modelData[jid]["nickname"] != nickname) {
                beginResetModel();
                _modelData[jid] = contact;
                qSort(_sortedJidNameList);
                endResetModel();
                //reset();
            }
            else {
                _modelData[jid] = contact;

                Q_EMIT dataChanged(index(row), index(row));
            }
        }
    }
    else {
        beginResetModel();
        _modelData[jid] = contact;
        _sortedJidNameList.append(pair);
        qSort(_sortedJidNameList);
        endResetModel();
        //reset();
    }
    for (int i = 0; i < _sortedJidNameList.size(); i++) {
        _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
    }
}

void ContactsModel::contactSynced(const QVariantMap &data)
{
    QVariantMap contact = data;
    QString jid = contact["jid"].toString();
    if (_modelData.keys().contains(jid)) {
        _modelData[jid]["timestamp"] = contact["timestamp"];
        QString message = contact["message"].toString();
        _modelData[jid]["message"] = message;
        int row = getIndexByJid(jid);
        if (row > -1) {
            int stamp = _modelData[jid]["lastmessage"].toInt();
            QString nickname = _modelData[jid]["nickname"].toString();

            if (contact.keys().contains("name") && !contact["name"].toString().isEmpty()) {
                QString name = contact["name"].toString();
                QString pushname = _modelData[jid]["pushname"].toString();

                bool resort = false;
                QString newName = getNicknameBy(jid, message, name, pushname);
                if (nickname != newName)
                    resort = true;
                nickname = newName;
                _modelData[jid]["nickname"] = nickname;

                bool blocked = false;
                if (jid.contains("-"))
                    blocked = getMuted(jid);
                else
                    blocked = getBlocked(jid);
                _modelData[jid]["blocked"] = blocked;

                if (resort) {
                    JidNameStampPair pair(jid, nickname, stamp);
                    _sortedJidNameList[row] = pair;
                    qSort(_sortedJidNameList);
                    for (int i = 0; i < _sortedJidNameList.size(); i++) {
                        _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
                    }

                    Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));
                }
                else {
                    JidNameStampPair pair(jid, nickname, stamp);
                    _sortedJidNameList[row] = pair;

                    Q_EMIT dataChanged(index(row), index(row));
                }
            }
            else {
                JidNameStampPair pair(jid, nickname, stamp);
                _sortedJidNameList[row] = pair;

                Q_EMIT dataChanged(index(row), index(row));
            }
        }
        if (_modelData[jid]["avatar"].toString().isEmpty())
            requestAvatar(jid);
    }
}

void ContactsModel::contactStatus(const QString &jid, const QString &message)
{
    if (_modelData.keys().contains(jid)) {
        int row = getIndexByJid(jid);
        if (row > -1) {
            _modelData[jid]["message"] = message;
            dataChanged(index(row), index(row));
        }
    }
}

void ContactsModel::newGroupSubject(const QVariantMap &data)
{
    QString jid = data["jid"].toString();
    if (_modelData.keys().contains(jid)) {
        QString message = data["message"].toString();
        QString subowner = data["subowner"].toString();
        int lastmessage = _modelData[jid]["lastmessage"].toInt();
        QString subtimestamp = data["subtimestamp"].toString();
        qDebug() << "Model upgate group subject" << message << "jid:" << jid << "lastmessage:" << QString::number(lastmessage);
        int row = getIndexByJid(jid);
        if (row > -1) {
            _modelData[jid]["message"] = message;
            _modelData[jid]["nickname"] = message;
            _modelData[jid]["subowner"] = subowner;
            _modelData[jid]["subtimestamp"] = subtimestamp;
            JidNameStampPair pair(jid, message, lastmessage);
            _sortedJidNameList[row] = pair;
            qSort(_sortedJidNameList);
            for (int i = 0; i < _sortedJidNameList.size(); i++) {
                _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
            }

            Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));
        }

        qDebug() << "New subject saved:" << message << "for jid:" << jid;
    }
}

void ContactsModel::contactsChanged()
{
    QVariantMap query;
    query["type"] = QueryType::ContactsGetAll;
    query["uuid"] = uuid;
    dbExecutor->queueAction(query);
}

QString ContactsModel::filter()
{
    return _filter;
}

bool ContactsModel::filtering()
{
    return _filtering;
}

void ContactsModel::deleteEverything()
{
    QVariantMap query;
    query["uuid"] = uuid;
    query["type"] = QueryType::DeleteEverything;
    dbExecutor->queueAction(query, 1000);
}

void ContactsModel::setFilter(const QString &newFilter)
{
    if (newFilter != _filter) {
        beginResetModel();
        _filter = newFilter;
        endResetModel();
    }
}

void ContactsModel::setFiltering(bool newFiltering)
{
    beginResetModel();
    _filtering = newFiltering;
    _sortedJidNameList.clear();
    if (_filtering) {
        foreach (const QString &key, _modelData.keys()) {
            JidNameStampPair pair(_modelData[key]["jid"].toString(), _modelData[key]["nickname"].toString(), 0);
            _sortedJidNameList.append(pair);
            _modelData[key]["modelindex"] = -1;
        }
        qSort(_sortedJidNameList);
    }
    else {
        foreach (const QString &key, _modelData.keys()) {
            JidNameStampPair pair(_modelData[key]["jid"].toString(), _modelData[key]["nickname"].toString(), _modelData[key]["lastmessage"].toInt());
            _sortedJidNameList.append(pair);
        }
        qSort(_sortedJidNameList);
    }
    for (int i = 0; i < _sortedJidNameList.size(); i++) {
        _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
    }
    endResetModel();
}

void ContactsModel::setUnread(const QString &jid, int count)
{
    //if (_activeJid != jid)
        setPropertyByJid(jid, "unread", count);
}

void ContactsModel::pushnameUpdated(const QString &jid, const QString &pushName)
{
    if (_modelData.keys().contains(jid) && (pushName != jid.split("@").first())) {
        setPropertyByJid(jid, "pushname", pushName);

        QString nickname = _modelData[jid]["nickname"].toString();
        QString pushname = _modelData[jid]["pushname"].toString();
        QString message = _modelData[jid]["message"].toString();
        QString name = _modelData[jid]["name"].toString();

        nickname = getNicknameBy(jid, message, name, pushname);

        /*if (!jid.contains("-") && !pushname.isEmpty()) {
            if (name == jid.split("@").first())
                nickname = pushName;
        }*/
        _modelData[jid]["nickname"] = nickname;
        JidNameStampPair pair(jid, nickname, _modelData[jid]["lastmessage"].toInt());
        int row = getIndexByJid(jid);
        if (row > -1) {
            _sortedJidNameList[row] = pair;
            qSort(_sortedJidNameList);
            for (int i = 0; i < _sortedJidNameList.size(); i++) {
                _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
            }
            Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));

            Q_EMIT nicknameChanged(jid, nickname);
        }
    }
}

void ContactsModel::presenceAvailable(const QString &jid)
{
    //qDebug() << "presenceAvailable" << jid;
    if (!_availableContacts.contains(jid))
        _availableContacts.append(jid);
    setPropertyByJid(jid, "available", true);
}

void ContactsModel::presenceUnavailable(const QString &jid)
{
    //qDebug() << "presenceUnavailable" << jid;
    if (_availableContacts.contains(jid))
        _availableContacts.removeAll(jid);
    setPropertyByJid(jid, "available", false);
}

void ContactsModel::presenceLastSeen(const QString jid, int timestamp)
{
    setPropertyByJid(jid, "timestamp", timestamp);
}

void ContactsModel::messageReceived(const QVariantMap &data)
{
    //qDebug() << "MessageReceived:" << data["jid"] << data["message"];
    QString jid = data["jid"].toString();
    int lastmessage = data["timestamp"].toInt();
    if (_modelData.keys().contains(jid)) {
        int row = getIndexByJid(jid);
        if (row > -1) {
            JidNameStampPair pair(jid, _modelData[jid]["nickname"].toString(), lastmessage);
            _sortedJidNameList[row] = pair;
            _modelData[jid]["lastmessage"] = lastmessage;
            qSort(_sortedJidNameList);
            for (int i = 0; i < _sortedJidNameList.size(); i++) {
                _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
            }

            Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));
        }
    }
}

void ContactsModel::contactsBlocked(const QStringList &jids)
{
    _blockedContacts = jids;
    foreach (const QString &jid, _modelData.keys()) {
        if (!jid.contains("-")) {
            if (jids.contains(jid))
                _modelData[jid]["blocked"] = true;
            else
                _modelData[jid]["blocked"] = false;
        }
    }
    Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));
}

void ContactsModel::groupsMuted(const QStringList &jids)
{
    _mutedGroups = jids;
    foreach (const QString &jid, _modelData.keys()) {
        if (jid.contains("-")) {
            if (jids.contains(jid))
                _modelData[jid]["blocked"] = true;
            else
                _modelData[jid]["blocked"] = false;
        }
    }
    Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));
}

void ContactsModel::contactsAvailable(const QStringList &jids)
{
    _availableContacts = jids;
    foreach (const QString &jid, _modelData.keys()) {
        if (jids.contains(jid))
            _modelData[jid]["available"] = true;
        else
            _modelData[jid]["available"] = false;

        Q_EMIT dataChanged(index(0), index(_modelData.count() - 1));
    }
}

void ContactsModel::dbResults(const QVariant &result)
{
    //qDebug() << "dbResults received";
    QVariantMap reply = result.toMap();
    if (reply["uuid"].toString() != uuid)
        return;
    int vtype = reply["type"].toInt();
    switch (vtype) {
    case QueryType::ContactsReloadContact: {
        QVariantMap contact = reply["contact"].toMap();
        contactChanged(contact);
        break;
    }
    case QueryType::ContactsGetAll: {
        QVariantList records = reply["contacts"].toList();
        qDebug() << "Received QueryGetContacts reply. Size:" << QString::number(records.size());
        if (records.size() > 0) {
            beginResetModel();
            _modelData.clear();
            _sortedJidNameList.clear();
            foreach (const QVariant &c, records) {
                QVariantMap data = c.toMap();
                QString jid = data["jid"].toString();
                QString pushname = data["pushname"].toString();
                QString name = data["name"].toString();
                QString message = data["message"].toString();
                qDebug() << "jid:" << jid << pushname << name << message;
                int stamp = data["lastmessage"].toInt();
                bool blocked = false;
                if (jid.contains("-"))
                    blocked = getMuted(jid);
                else
                    blocked = getBlocked(jid);
                data["blocked"] = blocked;
                bool available = getAvailable(jid);
                data["available"] = available;
                QString nickname = getNicknameBy(jid, message, name, pushname);
                data["nickname"] = nickname;
                _modelData[jid] = data;
                if (!_colors.keys().contains(jid))
                    _colors[jid] = generateColor();
                _sortedJidNameList.append(JidNameStampPair(jid, nickname, stamp));
                if (data["avatar"].toString().isEmpty())
                    requestAvatar(jid);
            }
            qSort(_sortedJidNameList);
            for (int i = 0; i < _sortedJidNameList.size(); i++) {
                _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
            }
            endResetModel();
            //reset();
        }
        //qDebug() << "inserted" << QString::number(_modelData.size()) << "rows";
        checkTotalUnread();
        break;
    }
    case QueryType::DeleteEverything: {
        Q_EMIT deleteEverythingSuccessful();
        break;
    }
    }
}

void ContactsModel::onActiveJidChanged(const QString &jid)
{
    _activeJid = jid;
}

int ContactsModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    //qDebug() << "Model count:" << _modelData.size();
    return _modelData.size();
}

QVariant ContactsModel::data(const QModelIndex &index, int role) const
{
    //qDebug() << "Model data" << index.row() << QString::number(role) << _roles[role];
    int row = index.row();
    if (row < 0 || row >= _modelData.count())
        return QVariant();
    QString jid = _sortedJidNameList.at(index.row())._jid;
    //qDebug() << "Model jid:" << jid << "data:" << _modelData[jid][_roles[role]];
    if (role == VisibleRole) {
        if (!_filtering)
            return QVariant::fromValue(true);
        else {
            bool var = _modelData[jid]["nickname"].toString().toLower().contains(_filter.toLower());
            return QVariant::fromValue(var);
        }
    }
    return _modelData[jid][_roles[role]];
}

bool ContactsModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    qDebug() << "Model setData" << index.row() << value << role;
    return false;
}

int ContactsModel::count()
{
    return _modelData.count();
}


void ContactsModel::renameContact(const QString &jid, const QString &name)
{
    int row = getIndexByJid(jid);
    if (row != -1) {
        _modelData[jid]["name"] = name;
        QString pushname = _modelData[jid]["pushname"].toString();
        int stamp = _modelData[jid]["lastmessage"].toInt();
        QString nickname;
        if (name == jid.split("@").first()) {
            if (!pushname.isEmpty())
                nickname = pushname;
            else
                nickname = name;
        }
        else {
            nickname = name;
        }
        _modelData[jid]["nickname"] = nickname;
        _sortedJidNameList[row] = JidNameStampPair(jid, nickname, stamp);
        qSort(_sortedJidNameList);
        for (int i = 0; i < _sortedJidNameList.size(); i++) {
            _modelData[_sortedJidNameList[i]._jid]["modelindex"] = i;
        }
        dataChanged(index(0), index(_modelData.count() - 1));

        QVariantMap query = _modelData[jid];
        query["type"] = QueryType::ContactsSaveModel;
        dbExecutor->queueAction(query);
    }
}

void ContactsModel::requestAvatar(const QString &jid)
{
    if (iface) {
        iface->call(QDBus::NoBlock, "getPicture", jid);
    }
}
