#ifndef FILEMODEL_H
#define FILEMODEL_H

#include <QObject>
#include <QAbstractListModel>

#include <QVector>
#include <QVariantMap>
#include <QVariantList>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>

class Filemodel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList filter READ getFilter WRITE setFilter FINAL)
    Q_PROPERTY(QString path READ getPath WRITE processPath FINAL)
    Q_PROPERTY(QString rpath READ getRpath WRITE processRpath FINAL)
    Q_PROPERTY(bool sorting READ getSorting WRITE setSorting)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum FileRoles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        SizeRole,
        TimestampRole,
        ExtensionRole,
        MimeRole,
        DirRole,
        ImageWidthRole,
        ImageHeightRole
    };
    explicit Filemodel(QObject *parent = 0);
    virtual ~Filemodel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }

private:
    void recursiveSearch(const QString &path);

    QHash<int, QByteArray> _roles;
    QVector<QVariantMap> _modelData;

    QStringList _filter;
    QStringList& getFilter();
    void setFilter(const QStringList &filter);

    QString _path;
    QString& getPath();
    void setPath(const QString &path);

    QString _rpath;
    QString& getRpath();
    void processRpath(const QString &rpath);

    bool _sorting;
    bool getSorting();
    void setSorting(bool newSorting);

public slots:
    void showRecursive(const QStringList &dirs);
    void processPath(const QString &path);
    void clear();
    int count();
    bool remove(int index);
    QVariantMap get(int index);

signals:
    void countChanged();

};

#endif // FILEMODEL_H
