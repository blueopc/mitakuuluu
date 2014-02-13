#include <QThreadPool>
#include <QDebug>

#include "queryexecutor.h"

static bool compareVListMap(const QVariant &item1, const QVariant &item2) {
    return item1.toMap()["name"].toString().toLower() < item2.toMap()["name"].toString().toLower();
}

QueryExecutor::QueryExecutor(QObject *parent) :
    QObject(parent)
{
    m_worker.setCallObject(this);

    db = QSqlDatabase::database();
    if (!db.isOpen()) {
        qDebug() << "QE Opening database";
        db = QSqlDatabase::addDatabase("QSQLITE");
        db.setDatabaseName("/home/nemo/.whatsapp/whatsapp.db");
        if (db.open())
            qDebug() << "QE opened database";
        else
            qWarning() << "QE failed to open database";
    }
    else {
        qWarning() << "QE used existing DB connection!";
    }

    if (db.isOpen()) {
        if (!db.tables().contains("login"))
            db.exec("CREATE TABLE login (name TEXT, password TEXT);");
        if (!db.tables().contains("contacts"))
            db.exec("CREATE TABLE contacts (jid TEXT, pushname TEXT, name TEXT, message TEXT, contacttype INTEGER, owner TEXT, subowner TEXT, timestamp INTEGER, subtimestamp INTEGER, avatar TEXT, unread INTEGER, lastmessage INTEGER);");
        if (db.tables().contains("account")) {
            QSqlQuery e("SELECT * FROM account LIMIT 1;");
            if (e.next()) {
                QString phoneNumber = e.value(0).toString();
                QString password = e.value(1).toString();

                db.exec("DELETE FROM login;");
                QSqlQuery acc;
                acc.prepare("INSERT INTO login VALUES (:name, :password);");
                acc.bindValue(":name", phoneNumber);
                acc.bindValue(":password", password);
                acc.exec();
            }
            db.exec("DROP TABLE account;");
        }
    }
}

void QueryExecutor::queueAction(QVariant msg, int priority) {
    m_worker.queueAction(msg, priority);
}

void QueryExecutor::processAction(QVariant message) {
    processQuery(message);
}

void QueryExecutor::processQuery(const QVariant &msg)
{
    QVariantMap query = msg.toMap();
    qDebug() << "QE Processing query:" << query["type"];
    if (!query.isEmpty()) {
        switch (query["type"].toInt()) {
        case QueryType::AccountGetData: {
            getAccountData(query);
            break;
        }
        case QueryType::AccountSetData: {
            setAccountData(query);
            break;
        }
        case QueryType::AccountRemoveData: {
            removeAccountData(query);
            break;
        }
        case QueryType::ContactsGetAll: {
            getContactsAll(query);
            break;
        }
        case QueryType::ContactsGetJids: {
            getContactsJids(query);
            break;
        }
        case QueryType::ConversationNotifyMessage: {
            messageNotify(query);
            break;
        }
        case QueryType::ContactsSetLastmessage: {
            setContactsLastmessage(query);
            break;
        }
        case QueryType::ConversationSaveMessage: {
            setConversationMessage(query);
            break;
        }
        case QueryType::ContactsUpdatePushname: {
            setContactPushname(query);
            break;
        }
        case QueryType::ContactsSetUnread: {
            setContactUnread(query);
            break;
        }
        case QueryType::ContactsSyncResults: {
            setContactsResults(query);
            break;
        }
        case QueryType::ContactsSetSync: {
            setContactSync(query);
            break;
        }
        case QueryType::ContactsSetAvatar: {
            setContactAvatar(query);
            break;
        }
        case QueryType::ContactsGetShareui: {
            getContactsShareui(query);
            break;
        }
        case QueryType::ConversationGetMessage:
        case QueryType::ConversationGetDownloadMessage: {
            getMessageModel(query);
            break;
        }
        case QueryType::ContactsUpdateGroup: {
            setGroupUpdated(query);
            break;
        }
        case QueryType::ConversationMessageStatus: {
            setMessageStatus(query);
            break;
        }
        case QueryType::ContactsSetLastSeen: {
            setContactLastSeen(query);
            break;
        }
        case QueryType::ContactsSaveModel: {
            setContactModel(query);
            break;
        }
        case QueryType::ContactsGetModel:
        case QueryType::ContactsReloadContact: {
            getContactModel(query);
            break;
        }
        case QueryType::ContactsRemove: {
            removeContact(query);
            break;
        }
        case QueryType::ConversationLoadLast: {
            getLastConversation(query);
            break;
        }
        case QueryType::ConversationLoadNext: {
            getNextConversation(query);
            break;
        }
        case QueryType::ConversationRemoveMessage: {
            removeMessage(query);
            break;
        }
        case QueryType::ConversationRemoveAll: {
            removeAllMessages(query);
            break;
        }
        case QueryType::ConversationSave: {
            saveConversation(query);
            break;
        }
        case QueryType::DeleteEverything: {
            deleteEverything(query);
            break;
        }
        default: {
            break;
        }
        }
    }
}

void QueryExecutor::getAccountData(QVariantMap &query)
{
    QSqlQuery sql("SELECT * FROM login LIMIT 1;", db);
    if (sql.next()) {
        query["username"] = sql.value(0);
        qDebug() << sql.value(0);
        query["password"] = sql.value(1);
        qDebug() << sql.value(1);
    }
    Q_EMIT actionDone(query);
}

void QueryExecutor::setAccountData(QVariantMap &query)
{
    qDebug() << "set account data" << query;
    db.exec("DELETE FROM login;");
    QSqlQuery sql(db);
    sql.prepare("INSERT INTO login VALUES (:username, :password);");
    sql.bindValue(":username", query["username"]);
    sql.bindValue(":password", query["password"]);
    sql.exec();
    Q_EMIT actionDone(query);
}

void QueryExecutor::removeAccountData(QVariantMap &query)
{
    if (db.tables().contains("login")) {
        db.exec("DELETE FROM login;");
    }
    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactsAll(QVariantMap &query)
{
    QSqlQuery sql("SELECT * FROM contacts", db);
    QVariantList contacts;
    while (sql.next()) {
        QVariantMap contact;
        for (int i = 0; i < sql.record().count(); i ++) {
            contact[sql.record().fieldName(i)] = sql.value(i);
        }
        contacts.append(contact);
    }
    query["contacts"] = contacts;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactsJids(QVariantMap &query)
{
    QSqlQuery sql("SELECT jid FROM contacts;", db);
    QVariantList jids;
    while (sql.next()) {
        jids.append(sql.value(0));
    }
    query["jids"] = jids;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactModel(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("SELECT * FROM contacts WHERE jid=(:jid);");
    sql.bindValue(":jid", query["jid"]);
    sql.exec();
    QVariantMap contact;
    if (sql.next()) {
        for (int i = 0; i < sql.record().count(); i ++) {
            contact[sql.record().fieldName(i)] = sql.value(i);
        }
    }
    query["contact"] = contact;
    Q_EMIT actionDone(query);
}

void QueryExecutor::messageNotify(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QSqlQuery e(db);
    e.prepare(QString("SELECT msgtype FROM u%1 WHERE msgid=(:msgid);").arg(jid.split("@").first().replace("-", "g")));
    e.bindValue(":msgid", query["msgid"]);
    e.exec();
    if (e.next())
        return;

    QSqlQuery sql(db);
    sql.prepare("SELECT name, message, avatar from contacts where jid=(:jid);");
    sql.bindValue(":jid", query["jid"]);
    sql.exec();
    if (sql.next()) {
        QString pushName = query["pushName"].toString();
        QString name = sql.value(0).toString();
        QString message = sql.value(1).toString();
        query["avatar"] = sql.value(2);
        QString nickname = pushName;
        if (jid.contains("-"))
            nickname = message;
        else if (name != jid.split("@").first() && !name.isEmpty())
            nickname = name;
        else if (pushName.isEmpty())
            nickname = jid.split("@").first();
        query["name"] = nickname;
    }
    else {
        query["name"] = query["jid"].toString().split("@").first();
        query["avatar"] = QVariant();
    }
    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactsLastmessage(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET lastmessage=(:lastmessage) WHERE jid=(:jid);");
    sql.bindValue(":lastmessage", query["lastmessage"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();
    Q_EMIT actionDone(query);
}

void QueryExecutor::setConversationMessage(QVariantMap &query)
{
    QString table = query["jid"].toString().split("@").first().replace("-","g");

    if (!db.tables().contains(table)) {
        db.exec(QString("CREATE TABLE u%1 (msgid TEXT, timestamp INTEGER, author TEXT, message TEXT, msgtype INTEGER, msgstatus INTEGER, mediatype INTEGER, mediaurl TEXT, medianame TEXT, medialat TEXT, medialon TEXT, mediasize INTEGER, mediathumb TEXT, mediamime TEXT, mediaduration INTEGER, localurl TEXT, broadcast INTEGER);").arg(table));
    }

    QSqlQuery sql(db);
    sql.prepare(QString("UPDATE u%1 SET msgtype=(:msgtype), msgstatus=(:msgstatus), mediaurl=(:mediaurl), medianame=(:medianame), mediasize=(:mediasize), mediathumb=(:mediathumb), mediaduration=(:mediaduration), localurl=(:localurl) WHERE msgid=(:msgid);").arg(table));
    sql.bindValue(":msgtype", query["msgtype"]);
    sql.bindValue(":msgstatus", query["msgstatus"]);
    sql.bindValue(":mediaurl", query["mediaurl"]);
    sql.bindValue(":medianame", query["medianame"]);
    sql.bindValue(":mediasize", query["mediasize"]);
    sql.bindValue(":mediathumb", query["mediathumb"]);
    sql.bindValue(":mediaduration", query["mediaduration"]);
    sql.bindValue(":localurl", query["localurl"]);
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();
    if (sql.numRowsAffected() == 0) {
        QSqlQuery i(db);
        i.prepare(QString("INSERT INTO u%1 VALUES (:msgid, :timestamp, :author, :message, :msgtype, :msgstatus, :mediatype, :mediaurl, :medianame, :medialat, :medialon, :mediasize, :mediathumb, :mediamime, :mediaduration, :localurl, :broadcast);").arg(table));
        i.bindValue(":msgid", query["msgid"]);
        i.bindValue(":timestamp", query["timestamp"]);
        i.bindValue(":author", query["author"]);
        i.bindValue(":message", query["message"]);
        i.bindValue(":msgtype", query["msgtype"]);
        i.bindValue(":msgstatus", query["msgstatus"]);
        i.bindValue(":mediatype", query["mediatype"]);
        i.bindValue(":mediaurl", query["mediaurl"]);
        i.bindValue(":medianame", query["medianame"]);
        i.bindValue(":medialat", query["medialat"]);
        i.bindValue(":medialon", query["medialon"]);
        i.bindValue(":mediasize", query["mediasize"]);
        i.bindValue(":mediathumb", query["mediathumb"]);
        i.bindValue(":mediamime", query["mediamime"]);
        i.bindValue(":mediaduration", query["mediaduration"]);
        i.bindValue(":localurl", query["localurl"]);
        i.bindValue(":broadcast", query["broadcast"]);
        i.exec();
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactPushname(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QString pushName = query["pushName"].toString();
    int timestamp = query["timestamp"].toInt();

    query["exists"] = true;

    QSqlQuery e(db);
    e.prepare("UPDATE contacts SET pushname=(:pushname) WHERE jid=(:jid);");
    e.bindValue(":pushname", jid.contains("-") ? jid : pushName);
    e.bindValue(":jid", jid);
    e.exec();
    if (e.numRowsAffected() == 0) {
        QSqlQuery ic(db);
        ic.prepare("INSERT INTO contacts VALUES (:jid, :pushname, :name, :message, :contacttype, :owner, :subowner, :timestamp, :subtimestamp, :avatar, :unread, :lastmessage);");
        ic.bindValue(":jid", jid);
        ic.bindValue(":pushname", pushName.isEmpty() ? jid.split("@").first() : pushName);
        ic.bindValue(":name", pushName.isEmpty() ? jid.split("@").first() : pushName);
        ic.bindValue(":message", "");
        ic.bindValue(":contacttype", jid.contains("-") ? 1 : 0);
        ic.bindValue(":owner", "");
        ic.bindValue(":subowner", "");
        ic.bindValue(":timestamp", 0);
        ic.bindValue(":subtimestamp", 0);
        ic.bindValue(":avatar", "");
        ic.bindValue(":unread", 0);
        ic.bindValue(":lastmessage", pushName.isEmpty() ? 0 : timestamp);
        ic.exec();

        query["exists"] = false;
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactUnread(QVariantMap query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET unread=(:unread) WHERE jid=(:jid);");
    sql.bindValue(":unread", query["unread"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactsResults(QVariantMap &query)
{
    int valid = 0;
    QString lastJid;
    QVariantList newJids;
    QVariantList avatars;
    QVariantList results = query["contacts"].toList();
    QVariantList blocked = query["blocked"].toList();
    foreach (QVariant vcontact, results) {

        QVariantMap contact = vcontact.toMap();
        //qDebug() << "Contact:" << contact;
        if (contact["w"].toInt() == 1 && db.isOpen()) {
            //qDebug() << contact;
            QString jid = contact["n"].toString();
            if (jid.contains("-"))
                jid += "@g.us";
            else
                jid += "@s.whatsapp.net";
            if (!blocked.contains(jid)) {
                QString message = contact["s"].toString();
                QString phone = contact["p"].toString();
                QString avatar = contact["a"].toString();
                QString name = contact["l"].toString();
                int timestamp = contact["t"].toInt();
                qDebug() << "Name:" << name << "Phone:" << phone << "Message" << message << "Jid:" << jid;

                QSqlQuery uc;
                //uc.prepare("UPDATE contacts SET name=(:name), message=(:message), contacttype=(:contacttype), timestamp=(:timestamp) WHERE jid=(:jid);");
                uc.prepare("UPDATE contacts SET name=(:name), message=(:message) WHERE jid=(:jid);");
                uc.bindValue(":name", name);
                uc.bindValue(":message", message);
                //uc.bindValue(":contacttype", 0);
                //uc.bindValue(":timestamp", timestamp);
                uc.bindValue(":jid", jid);
                uc.exec();

                if (uc.lastError().type() != QSqlError::NoError)
                    qDebug() << "[contacts] Update pushname result:" << uc.lastError();

                if (uc.numRowsAffected() == 0) {
                    qDebug() << "insert new contact:" << name;
                    QSqlQuery ic;
                    ic.prepare("INSERT INTO contacts VALUES (:jid, :pushname, :name, :message, :contacttype, :owner, :subowner, :timestamp, :subtimestamp, :avatar, :unread, :lastmessage);");
                    ic.bindValue(":jid", jid);
                    ic.bindValue(":pushname", name);
                    ic.bindValue(":name", name);
                    ic.bindValue(":message", message);
                    ic.bindValue(":contacttype", 0);
                    ic.bindValue(":owner", "");
                    ic.bindValue(":subowner", "");
                    ic.bindValue(":timestamp", 0);
                    ic.bindValue(":subtimestamp", 0);
                    ic.bindValue(":avatar", avatar);
                    ic.bindValue(":unread", 0);
                    ic.bindValue(":lastmessage", 0);
                    ic.exec();

                    if (ic.lastError().type() != QSqlError::NoError)
                        qDebug() << "[contacts] Insert error:" << ic.lastError();

                    newJids.append(jid);

                    if (results.length() == 1) {
                        QVariantMap contact;
                        contact["jid"] = jid;
                        contact["name"] = name;
                        contact["pushname"] = name;
                        contact["nickname"] = name;
                        contact["message"] = message;
                        contact["contacttype"] = 0;
                        contact["owner"] = QString();
                        contact["subowner"] = QString();
                        contact["timestamp"] = timestamp;
                        contact["subtimestamp"] = 0;
                        contact["avatar"] = avatar;
                        contact["available"] = false;
                        contact["unread"] = 0;
                        contact["lastmessage"] = 0;
                        contact["blocked"] = false;

                        query["contact"] = contact;
                    }
                }
                else if (results.length() == 1) {
                    QVariantMap contact;
                    contact["name"] = name;
                    contact["jid"] = jid;
                    contact["message"] = message;
                    contact["timestamp"] = timestamp;

                    query["sync"] = contact;
                }
                if (avatar.isEmpty())
                    avatars.append(jid);
                valid ++;
                lastJid = jid;
            }
        }
    }
    query["jids"] = newJids;

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactSync(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET message=(:message), timestamp=(:timestamp) WHERE jid=(:jid);");
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactAvatar(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET avatar=(:avatar) WHERE jid=(:jid);");
    sql.bindValue(":avatar", query["avatar"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactsShareui(QVariantMap &query)
{
    QVariantList model;
    QSqlQuery sql("SELECT jid, name, pushname, message, avatar FROM contacts;", db);
    while (sql.next()) {
        QVariantMap contact;
        contact["avatar"] = sql.value(4);
        QString jid = sql.value(0).toString();
        QString name = sql.value(1).toString();
        QString pushname = sql.value(2).toString();
        QString message = sql.value(3).toString();
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
        contact["name"] = nickname;
        contact["jid"] = jid;
        model.append(contact);
    }
    if (!model.isEmpty()) {
        qSort(model.begin(), model.end(), compareVListMap);
    }
    query["model"] = model;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getMessageModel(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QString table = jid.split("@").first().replace("-", "g");
    QSqlQuery sql(db);
    sql.prepare(QString("SELECT * FROM u%1 WHERE msgid=(:msgid);").arg(table));
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();
    QVariantMap message;
    if (sql.next()) {
        for (int i = 0; i < sql.record().count(); i ++) {
            message[sql.record().fieldName(i)] = sql.value(i);
        }
    }
    message["jid"] = query["jid"];
    query["message"] = message;
    Q_EMIT actionDone(query);
}

void QueryExecutor::setGroupUpdated(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET message=(:message), subowner=(:subowner), subtimestamp=(:subtimestamp) WHERE jid=(:jid);");
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":subowner", query["subowner"]);
    sql.bindValue(":subtimestamp", query["subtimestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    query["exists"] = sql.numRowsAffected() != 0;

    Q_EMIT actionDone(query);
}

void QueryExecutor::setMessageStatus(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("UPDATE u%1 SET msgstatus=(:msgstatus) WHERE msgid=(:msgid);").arg(jid.split("@").first().replace("-", "g")));
    sql.bindValue(":msgstatus", query["msgstatus"]);
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactLastSeen(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET timestamp=(:timestamp) WHERE jid=(:jid);");
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactModel(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET owner=(:owner), message=(:message), name=(:name), subowner=(:subowner), subtimestamp=(:subtimestamp), timestamp=(:timestamp)  WHERE jid=(:jid);");
    sql.bindValue(":owner", query["owner"]);
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":name", query["name"]);
    sql.bindValue(":subowner", query["subowner"]);
    sql.bindValue(":subtimestamp", query["subtimestamp"]);
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    if (sql.numRowsAffected() == 0) {
        QSqlQuery ic;
        ic.prepare("INSERT INTO contacts VALUES (:jid, :pushname, :name, :message, :contacttype, :owner, :subowner, :timestamp, :subtimestamp, :avatar, :unread, :lastmessage);");
        ic.bindValue(":jid", query["jid"]);
        ic.bindValue(":pushname", query["pushname"]);
        ic.bindValue(":name", query["name"]);
        ic.bindValue(":message", query["message"]);
        ic.bindValue(":contacttype", query["contacttype"]);
        ic.bindValue(":owner", query["owner"]);
        ic.bindValue(":subowner", query["subowner"]);
        ic.bindValue(":timestamp", query["timestamp"]);
        ic.bindValue(":subtimestamp", query["subtimestamp"]);
        ic.bindValue(":avatar", "");
        ic.bindValue(":unread", 0);
        ic.bindValue(":lastmessage", 0);
        ic.exec();
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::removeContact(QVariantMap &query)
{
    QString jid = query["jid"].toString();

    QSqlQuery sql(db);
    sql.prepare("DELETE FROM contacts WHERE jid=(:jid);");
    sql.bindValue(":jid", jid);
    sql.exec();

    QString table = QString("u%1").arg(jid.split("@").first().replace("-", ""));
    if (db.tables().contains(table)) {
        db.exec(QString("DROP TABLE %1;").arg(table));
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::getLastConversation(QVariantMap &query)
{
    QString table = query["table"].toString();
    QSqlQuery sql(QString("SELECT * FROM u%1 ORDER BY timestamp DESC LIMIT 20;").arg(table), db);
    QVariantList messages;
    while (sql.next()) {
        QVariantMap message;
        for (int i = 0; i < sql.record().count(); i ++) {
            message[sql.record().fieldName(i)] = sql.value(i);
        }
        messages.append(message);
    }
    query["messages"] = messages;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getNextConversation(QVariantMap &query)
{
    QString table = query["table"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("SELECT * FROM u%1 WHERE timestamp<(:timestamp) ORDER BY timestamp DESC LIMIT (:count);").arg(table));
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":count", query["count"]);
    sql.exec();
    QVariantList messages;
    while (sql.next()) {
        QVariantMap message;
        for (int i = 0; i < sql.record().count(); i ++) {
            message[sql.record().fieldName(i)] = sql.value(i);
        }
        messages.append(message);
    }
    query["messages"] = messages;

    Q_EMIT actionDone(query);
}

void QueryExecutor::removeMessage(QVariantMap &query)
{
    QString table = query["table"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("DELETE FROM u%1 WHERE msgid=(:msgid);").arg(table));
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::removeAllMessages(QVariantMap &query)
{
    QString table = query["table"].toString();
    db.exec(QString("DELETE FROM u%1;").arg(table));

    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET lastmessage=(:lastmessage) WHERE jid=(:jid);");
    sql.bindValue(":lastmessage", 0);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::saveConversation(QVariantMap &query)
{
    QString table = query["table"].toString();
    QString jid = query["jid"].toString();
    if (!QDir("/home/nemo/Documents/WhatsApp/").exists())
        QDir::home().mkpath("/home/nemo/Documents/WhatsApp/");
    QFile conv("/home/nemo/Documents/WhatsApp/" + query["name"].toString() + ".txt");
    if (conv.open(QFile::WriteOnly | QFile::Text)) {
        QTextStream out(&conv);
        QSqlQuery sql(QString("SELECT * FROM u%1 ORDER BY timestamp ASC;").arg(table), db);
        while (sql.next()) {
            QVariantMap message;
            for (int i = 0; i < sql.record().count(); i ++) {
                message[sql.record().fieldName(i)] = sql.value(i);
            }
            QString timestamp = QDateTime::fromTime_t(message["timestamp"].toInt()).toString("dd MMM hh:mm:ss");
            QString text;
            if (message["msgtype"].toInt() == 2)
                text = message["message"].toString();
            else if (message["msgtype"].toInt() == 3) {
                switch (message["mediatype"].toInt()) {
                case 1: text = "picture " + message["mediaurl"].toString(); break;
                case 2: text = "audio " + message["mediaurl"].toString(); break;
                case 3: text = "video " + message["mediaurl"].toString(); break;
                case 4: text = "contact " + message["medianame"].toString(); break;
                case 5: text = "location LAT: " + message["medialon"].toString() + " LON: " + message["medialat"].toString(); break;
                default: text = "unknown media"; break;
                }
            }
            QString fmt;
            if (jid.contains("-")) {
                fmt = QString("%1 <%2>: %3").arg(timestamp).arg(query["name"].toString()).arg(text);
            }
            else {
                fmt = QString("[%1] %2").arg(timestamp).arg(text);
            }
            out << fmt << "\n";
        }
        conv.close();
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::deleteEverything(QVariantMap &query)
{
    foreach (const QString &table, db.tables()) {
        db.exec(QString("DROP TABLE %1;").arg(table));
    }
    QFile log1("/home/nemo/.whatsapp/whatsapp.log");
    if (log1.exists())
        log1.remove();

    QFile log2("/home/nemo/.whatsapp/logs/whatsapp_log1.tar.gz");
    if (log2.exists())
        log2.remove();

    QFile log3("/home/nemo/.whatsapp/logs/whatsapp_log2.tar.gz");
    if (log3.exists())
        log3.remove();

    QFile log4("/home/nemo/.whatsapp/logs/whatsapp_log3.tar.gz");
    if (log4.exists())
        log4.remove();

    QFile settings("/home/nemo/.config/coderus/whatsapp.conf");
    if (settings.exists())
        settings.remove();

    Q_EMIT actionDone(query);
}

QueryExecutor* QueryExecutor::GetInstance()
{
    static QueryExecutor* lsSingleton = NULL;
    if (!lsSingleton) {
        lsSingleton = new QueryExecutor(0);
    }
    return lsSingleton;
}
