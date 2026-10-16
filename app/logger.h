#pragma once

#include <QMutex>
#include <QObject>
#include <QString>

// M6 Logger stub: file-backed Qt message handler with level filtering.
// Wiring (main.cpp):
//   Logger::instance().install(saveLog, logFile, logLevel)
// Settings keys (m3/diagnostics/*):
//   saveLog  — master toggle (default ON per M3, honors SettingsStore.saveLog)
//   logFile  — explicit path; empty => default app-data location
//              (~/.local/share/VLC/"VLC Redesign"/vlc-redesign.log)
//   logLevel — "Errors only" | "Warnings" | "Info" | "Debug"
// Filter mapping (QtMsgType):
//   Errors only -> Critical + Fatal only
//   Warnings    -> + Warning
//   Info        -> + Info
//   Debug       -> + Debug (everything)
// Console always keeps a copy (qInfo fallback) so dev builds stay live.
// exportLogBundle(destPath): writes a plain-text bundle (log tail + settings
// dump + versions) for bug reports. Real .zip compression is a follow-up;
// the .logbundle.txt suffix keeps the stub honest in the UI.
class Logger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool saveLog READ saveLog WRITE setSaveLog NOTIFY saveLogChanged)
    Q_PROPERTY(QString logFile READ logFile NOTIFY logFileChanged)
    Q_PROPERTY(QString logLevel READ logLevel WRITE setLogLevel NOTIFY logLevelChanged)
public:
    static Logger &instance();

    // Installs the global message handler (idempotent). Call once from main.
    Q_INVOKABLE void install(bool saveLog, const QString &logFile, const QString &logLevel);
    Q_INVOKABLE void setSaveLog(bool v);
    Q_INVOKABLE void setLogLevel(const QString &v);

    bool saveLog() const;
    QString logFile() const;
    QString logLevel() const;

    // Resolved file path (explicit or default app-data location).
    Q_INVOKABLE QString resolvedLogFile() const;

    // Writes a diagnostics bundle: header + settings dump + log tail.
    // Returns the bundle path on success, "" on failure.
    Q_INVOKABLE QString exportLogBundle(const QString &destPath = QString());

    // Test hook: log one line per level through the filter.
    Q_INVOKABLE void selfTest();

signals:
    void saveLogChanged();
    void logFileChanged();
    void logLevelChanged();

private:
    explicit Logger(QObject *parent = nullptr);
    static void handler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg);
    bool passesFilter(QtMsgType type) const;
    void appendLine(const QString &line);
    QString defaultLogFile() const;

    mutable QMutex m_mutex;
    bool m_saveLog = true;
    QString m_logFile; // explicit override; empty => default
    QString m_logLevel = QStringLiteral("Errors only");
    bool m_installed = false;
};
