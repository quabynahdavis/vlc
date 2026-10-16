#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <QDebug>

#include <vlc/vlc.h>

#include "libraryservice.h"
#include "settingsstore.h"

// M0 hello-video entry point.
// Usage: ./vlc-redesign-m0 [media-file-or-url]
// M0 stub: logs libVLC version, logs CLI arg, forwards it to QML as
// `initialSource`. Actual libVLC render integration lands in M1+.

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("VLC Redesign M0"));
    app.setOrganizationName(QStringLiteral("VLC"));

    // --- libVLC version log stub (M0) ---
    const char *vlcVersion = libvlc_get_version();
    qInfo() << "libVLC version:" << (vlcVersion ? vlcVersion : "(unknown)");

    libvlc_instance_t *vlc = libvlc_new(0, nullptr);
    if (!vlc) {
        qWarning() << "libVLC init failed (M0 stub continues without playback engine)";
    } else {
        // Stub only: prove headers + link work. Real player setup in M1+.
        libvlc_release(vlc);
    }

    // --- CLI arg: play file if provided (stub ok) ---
    QUrl initialSource;
    if (argc > 1) {
        initialSource = QUrl::fromUserInput(QString::fromLocal8Bit(argv[1]));
        qInfo() << "M0 media arg:" << QString::fromLocal8Bit(argv[1])
                << "->" << initialSource.toString()
                << "(stub: forwarded to QML MediaPlayer)";
    } else {
        qInfo() << "M0: no media arg, showing hello-video stage";
    }

    QQmlApplicationEngine engine;

    // M2 library store: SQLite schema ready before QML binds the fixture.
    LibraryService libraryService;
    libraryService.ensureSchema();
    engine.rootContext()->setContextProperty(QStringLiteral("LibraryService"),
                                             &libraryService);

    // M3 settings store: QSettings-backed, namespaced keys, migratable.
    SettingsStore settingsStore;
    engine.rootContext()->setContextProperty(QStringLiteral("SettingsStore"),
                                             &settingsStore);

    if (initialSource.isValid() && !initialSource.isEmpty()) {
        engine.setInitialProperties({{QStringLiteral("initialSource"), initialSource}});
    }

    engine.loadFromModule(QStringLiteral("VlcM0"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
