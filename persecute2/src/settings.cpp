#include "settings.h"
#include <QStringList>
#include <QDebug>

Settings::Settings(QObject *parent) :
    QObject(parent)
{
    settings = new QSettings("coderus", "whatsapp", this);
}

void Settings::setValue(const QString &key, const QVariant &value)
{
    if (settings) {
        settings->setValue(key, value);
    }
}

QVariant Settings::value(const QString &key, const QVariant &defaultValue)
{
    if (settings) {
        QVariant value = settings->value(key, defaultValue);
        switch (defaultValue.type()) {
        case QVariant::Bool:
            return value.toBool();
        case QVariant::Double:
            return value.toDouble();
        case QVariant::Int:
            return value.toInt();
        case QVariant::String:
            return value.toString();
        case QVariant::StringList:
            return value.toStringList();
        case QVariant::List:
            return value.toList();
        default:
            return value;
        }
    }
    return QVariant();
}

void Settings::sync()
{
    if (settings)
        settings->sync();
}
