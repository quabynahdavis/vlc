#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSettings>
#include <QTranslator>
#include <QUrl>
#include <QDebug>

#include <vlc/vlc.h>

#include "libraryservice.h"
#include "logger.h"
#include "settingsstore.h"

// M0 hello-video entry point.
// Usage: ./vlc-redesign-m0 [media-file-or-url]
// M0 stub: logs libVLC version, logs CLI arg, forwards it to QML as
// `initialSource`. Actual libVLC render integration lands in M1+.
// M6: Logger installs first (file + Errors-only filter from stored settings),
// then a QTranslator stub follows SettingsStore.language (English ships, no
// .qm bundled yet — see app/i18n/; Pseudo-RTL flips layout direction so RTL
// mirroring can be checked without a translation file).

namespace {

QTranslator *g_translator = nullptr;

bool isPseudoRtl(const QString &lang)
{
    return lang.trimmed().compare(QStringLiteral("Pseudo-RTL (test)"),
                                  Qt::CaseInsensitive) == 0;
}

void applyLanguage(QGuiApplication &app, const QString &lang)
{
    // Layout direction: RTL only for the pseudo-RTL test entry; every real
    // locale stays LTR until translated .qm files ship (follow-up).
    app.setLayoutDirection(isPseudoRtl(lang) ? Qt::RightToLeft : Qt::LeftToRight);

    if (g_translator) {
        app.removeTranslator(g_translator);
        delete g_translator;
        g_translator = nullptr;
    }
    if (lang.isEmpty() || lang == QStringLiteral("English") || isPseudoRtl(lang)) {
        qInfo() << "M6 i18n: language =" << lang
                << (isPseudoRtl(lang) ? "(pseudo-RTL: mirrored layout, English strings)"
                                      : "(built-in English, no .qm needed)");
        return;
    }
    // Stub: try the bundled .qm (ships in a follow-up via qt_add_translations);
    // until then every non-English entry falls back to English with a log.
    g_translator = new QTranslator(&app);
    const QString base = QStringLiteral(":/i18n/vlc-redesign_%1").arg(lang.toLower());
    if (g_translator->load(base))
        app.installTranslator(g_translator);
    else
        qInfo() << "M6 i18n: no .qm for" << lang << "(stub: English fallback, see app/i18n/)";
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("VLC Redesign M0"));
    app.setOrganizationName(QStringLiteral("VLC"));

    // --- M6 logger first: file + level filter before anything else logs ---
    {
        QSettings probe(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"));
        Logger::instance().install(
            probe.value(QStringLiteral("m3/diagnostics/saveLog"), true).toBool(),
            probe.value(QStringLiteral("m3/diagnostics/logFile"), QString()).toString(),
            probe.value(QStringLiteral("m3/diagnostics/logLevel"), QStringLiteral("Errors only")).toString());
    }

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
    // M6 diagnostics surface for the Export-log-bundle button.
    engine.rootContext()->setContextProperty(QStringLiteral("Logger"),
                                             &Logger::instance());

    // M6 i18n: apply at startup, re-apply on every language change.
    applyLanguage(app, settingsStore.language());
    QObject::connect(&settingsStore, &SettingsStore::languageChanged, [&app, &settingsStore]() {
        applyLanguage(app, settingsStore.language());
    });
    // M6 logger follows the Diagnostics toggles live.
    QObject::connect(&settingsStore, &SettingsStore::saveLogChanged, [&settingsStore]() {
        Logger::instance().setSaveLog(settingsStore.saveLog());
    });
    QObject::connect(&settingsStore, &SettingsStore::logLevelChanged, [&settingsStore]() {
        Logger::instance().setLogLevel(settingsStore.logLevel());
    });

    if (initialSource.isValid() && !initialSource.isEmpty()) {
        engine.setInitialProperties({{QStringLiteral("initialSource"), initialSource}});
    }

    engine.loadFromModule(QStringLiteral("VlcM0"), QStringLiteral("Main"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
