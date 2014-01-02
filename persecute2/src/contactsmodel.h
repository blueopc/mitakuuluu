#ifndef CONTACTSMODEL_H
#define CONTACTSMODEL_H

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <QStringList>
#include <QAbstractListModel>

#include <QtSql/QtSql>

#include <QtDBus/QtDBus>

#include <QColor>

#include <QDebug>

#include "threadworker/queryexecutor.h"

class JidNameStampPair
{
public:
    JidNameStampPair(const QString &jid, const QString &name, int stamp) {
        _jid = jid;
        _name = name;
        _stamp = stamp;
    }
    bool operator <(const JidNameStampPair &target) const {
        if (_stamp > target._stamp)
            return true;
        else if (_stamp < target._stamp)
            return false;
        else/* if (_stamp == target._stamp)*/ {
            return _name.toLower() < target._name.toLower();
        }
        //bool result = _name.toLower() < target._name.toLower();
        //return result;
    }
    JidNameStampPair& operator =(const JidNameStampPair &from) {
        _jid = from._jid;
        _name = from._name;
        _stamp = from._stamp;
        return *this;
    }
    friend QDebug operator<< (QDebug d, const JidNameStampPair &data) {
        d << "{" << data._jid << ":" << data._name << "(" << data._stamp << ")}";
        return d;
    }
    QString _jid;
    QString _name;
    int _stamp;
};

class ContactsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool notifyEvents READ getNotify WRITE setNotify FINAL)
    Q_PROPERTY(int totalUnread READ getTotalUnread NOTIFY totalUnreadChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter FINAL)
    Q_PROPERTY(bool filtering READ filtering WRITE setFiltering FINAL)
    Q_PROPERTY(int count READ count FINAL)
public:
    enum ContactRoles {
        JidRole = Qt::UserRole + 1,
        PushnameRole,
        NameRole,
        NicknameRole,
        StatusRole,
        ContacttypeRole,
        GroupOwnerRole,
        GroupMessageOwnerRole,
        TimestampRole,
        MessageTimestampRole,
        AvatarRole,
        UnreadCountRole,
        AvailableRole,
        LastMessageStampRole,
        BlockedRole,
        VisibleRole
    };

    explicit ContactsModel(QObject *parent = 0);
    virtual ~ContactsModel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }

public slots:
    int count();
    void reloadContact(const QString &jid);
    void setPropertyByJid(const QString &jid, const QString &name, const QVariant &value);
    void deleteContact(const QString &jid);
    QVariantMap getModel(const QString &jid);
    QVariantMap get(int index);
    QColor getColorForJid(const QString &jid, bool inverted = false);
    void renameContact(const QString &jid, const QString &name);
    void requestAvatar(const QString &jid);

    void clear();
    void contactsChanged();
    QString filter();

    bool filtering();

    void deleteEverything();

private:
    bool getAvailable(const QString &jid);
    bool getBlocked(const QString &jid);
    bool getMuted(const QString jid);

    int getIndexByJid(const QString &jid);
    QString getNicknameBy(const QString &jid, const QString &message, const QString &name, const QString &pushname);

    QColor generateColor();
    QHash<QString, QColor> _colors;

    QList<JidNameStampPair> _sortedJidNameList;
    QHash<QString, QVariantMap> _modelData;
    QHash<QString, QVariantMap> _filterData;
    QHash<int, QByteArray> _roles;
    QSqlDatabase db;
    QDBusInterface *iface;

    QueryExecutor *dbExecutor;

    bool _notify;
    bool getNotify();
    void setNotify(bool value);

    QString uuid;
    QString _activeJid;

    int _totalUnread;
    int getTotalUnread();
    void checkTotalUnread();

    QString _filter;
    void setFilter(const QString &newFilter);

    bool _filtering;
    void setFiltering(bool newFiltering);

    QStringList _blockedContacts;
    QStringList _mutedGroups;
    QStringList _availableContacts;

signals:
    void nicknameChanged(QString pjid, QString nickname);
    void totalUnreadChanged();
    void deleteEverythingSuccessful();

private slots:
    void pictureUpdated(const QString &jid, const QString &path);
    void contactChanged(const QVariantMap &data);
    void contactSynced(const QVariantMap &data);
    void contactStatus(const QString &jid, const QString &message);
    void newGroupSubject(const QVariantMap &data);
    void setUnread(const QString &jid, int count);
    void pushnameUpdated(const QString &jid, const QString &pushName);
    void presenceAvailable(const QString &jid);
    void presenceUnavailable(const QString &jid);
    void presenceLastSeen(const QString jid, int timestamp);
    void messageReceived(const QVariantMap &data);
    void dbResults(const QVariant &result);
    void onActiveJidChanged(const QString &jid);
    void contactsBlocked(const QStringList &jids);
    void groupsMuted(const QStringList &jids);
    void contactsAvailable(const QStringList &jids);
};

#endif // CONTACTSMODEL_H
