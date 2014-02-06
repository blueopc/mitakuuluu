/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <QtQuick>
#include <sailfishapp.h>

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>

#include <QFile>
#include <QTextStream>
#include <QDateTime>

#include "constants.h"

#include "dbusobject.h"
#include "contactsmodel.h"
#include "conversationmodel.h"
#include "filesmodel.h"
#include "WhatsApp.h"
//#include "GConf.h"
#include "settings.h"

#include <QDebug>

#include <QLocale>
#include <QTranslator>

//WhatsApp *whatsapp = NULL;

void writeLog(const QString &type, const QMessageLogContext &context, const QString &message)
{
    QString time = QDateTime::currentDateTime().toString("hh:mm:ss");
    QFile file("/home/nemo/.whatsapp/whatsapp.log");
    if (file.open(QIODevice::Append | QIODevice::Text))
    {
        QTextStream out(&file);
        out << type << time << " CLIENT] ";
        out << context.file << ":" << context.line << " " << context.function << ": ";
        out << message << '\n';
        file.close();
    }
    //QTextStream(stdout) << context.file << ":" << context.line << " " << context.function << "\n";
    QTextStream(stdout) << type << time <<  " CLIENT] " << message << '\n';
}

void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    switch (type) {
    case QtDebugMsg:
        writeLog("[D ", context, msg);
        break;
    case QtWarningMsg:
        writeLog("[W ", context, msg);
        break;
    case QtCriticalMsg:
        writeLog("[C ", context, msg);
        break;
    case QtFatalMsg:
        writeLog("[F ", context, msg);
        abort();
    }
}

void quitHandler(int) {
    //if (whatsapp)
    //    whatsapp->exit();
}

Q_DECL_EXPORT
int main(int argc, char *argv[])
{
    setuid(getpwnam("nemo")->pw_uid);
    setgid(getgrnam("privileged")->gr_gid);
    if (!QDir("/home/nemo/.whatsapp").exists())
        QDir().mkpath("/home/nemo/.whatsapp");
    qInstallMessageHandler(messageHandler);
    qDebug() << "Starting application";
    QGuiApplication *app = SailfishApp::application(argc, argv);
    QQuickView *view = SailfishApp::createView();
    view->rootContext()->setContextProperty("view", view);
    view->rootContext()->setContextProperty("app", app);

    qDebug() << "Creating Settings object";
    Settings *settings = new Settings(view);
    view->rootContext()->setContextProperty("settings", settings);

    qDebug() << "Checking if directories exists";
    QDir home = QDir::home();
    if (!home.exists(home.path() + "/.whatsapp/logs/"))
        home.mkpath(home.path() + "/.whatsapp/logs/");

    if (!home.exists(home.path() + "/.config/coderus"))
        home.mkpath(home.path() + "/.config/coderus");

    qDebug() << "Registering QML types";
    qmlRegisterType<ContactsModel>("org.coderus.mitakuuluu", 1, 0, "ContactsModel");
    qmlRegisterType<ConversationModel>("org.coderus.mitakuuluu", 1, 0, "ConversationModel");
    qmlRegisterType<FilesModel>("org.coderus.mitakuuluu", 1, 0, "FilesModel");

//    GConf *gconf = new GConf(view);
//    view->rootContext()->setContextProperty("gconf", gconf);

    qDebug() << "Creating WhatsApp object";
    WhatsApp *whatsapp = new WhatsApp(view);
    view->rootContext()->setContextProperty("whatsapp", whatsapp);

    QStringList locales;
    QStringList localeNames;
    QString baseName("/usr/share/harbour-mitakuuluu/locales/");
    QDir localesDir(baseName);
    if (localesDir.exists()) {
        locales = localesDir.entryList(QStringList() << "*.qm", QDir::Files | QDir::NoDotAndDotDot, QDir::Name | QDir::IgnoreCase);
    }
    foreach (const QString &locale, locales) {
        localeNames << QString("%1 (%2)")
                               .arg(QLocale::languageToString(QLocale(locale).language()))
                               .arg(QLocale::countryToString(QLocale(locale).country()));
    }
    view->rootContext()->setContextProperty("locales", locales);
    view->rootContext()->setContextProperty("localeNames", localeNames);

    int localeIndex = 0;
    QString currentLocale = settings->value("locale", QString("%1.qm").arg(QLocale::system().name().split(".").first())).toString();
    qDebug() << "currentLocale:" << currentLocale;
    if (locales.contains(currentLocale)) {
        qDebug() << "loading" << currentLocale;
        localeIndex = locales.indexOf(currentLocale);
        whatsapp->setLocale(currentLocale);
    }
    view->rootContext()->setContextProperty("localeIndex", localeIndex);

    QStringList customDelegates;
    QDir delegates("/home/nemo/.whatsapp/delegates/");
    if (delegates.exists()) {
        customDelegates = delegates.entryList(QStringList() << "*.qml", QDir::Files | QDir::NoDotAndDotDot, QDir::Name | QDir::IgnoreCase);
    }
    view->rootContext()->setContextProperty("conversationDelegates", customDelegates);

    qDebug() << "Checking if emoji actually exists";
    QFile emoji("/usr/share/harbour-mitakuuluu/emoji/1F4B5.png");
    if (emoji.exists()) {
        qDebug() << "Have whatsapp emoji";
        view->rootContext()->setContextProperty("emojiSupport", QVariant::fromValue(true));
        view->rootContext()->setContextProperty("emojiPath", "/usr/share/harbour-mitakuuluu/emoji/");
    }
    else {
        qDebug() << "Have no emoji";
        view->rootContext()->setContextProperty("emojiSupport", QVariant::fromValue(false));
        view->rootContext()->setContextProperty("emojiPath", "");
    }

    qDebug() << "Showing main widow";
    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->showFullScreen();

    qDebug() << "View showed";

    qDebug() << "Creating DBus objects and connecting to signals";
    DBusObject *dbusObject = new DBusObject(view);
    //QObject::connect(view->engine(), SIGNAL(quit()), view, SLOT(close()));
    QObject::connect(dbusObject, SIGNAL(doExit()), view, SLOT(close()));
    QObject::connect(dbusObject, SIGNAL(doExit()), whatsapp, SLOT(exit()));
    QObject::connect(dbusObject, SIGNAL(notification(QString)), whatsapp, SLOT(setPendingJid(QString)));
    dbusObject->initialize();

    int retVal = app->exec();
    qDebug() << "Destroying DBus object";
    if (dbusObject)
        delete dbusObject;
    qDebug() << "Destroying settings object";
    if (settings)
        delete settings;
    qDebug() << "Destroying client class";
    if (whatsapp)
        delete whatsapp;
    qDebug() << "Destroying view object";
    if (view)
        delete view;
    qDebug() << "Destroying application";
    if (app)
        delete app;
    qDebug() << "App exiting with code:" << QString::number(retVal);
    return retVal;
}

