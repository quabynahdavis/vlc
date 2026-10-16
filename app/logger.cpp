#include "logger.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>

namespace {

int levelRank(const QString &level)
{
    const QString l = level.trimmed().toLower();
    if (l == QStringLiteral("debug"))
        return 3;
    if (l == QStringLiteral("info"))
        return 2;
    if (l == QStringLiteral("warnings"))
        return 1;
    return 0; // "Errors only" default
}

int typeRank(QtMsgType t)
{
    switch (t) {
    case QtDebugMsg: return 3;
    case QtInfoMsg: return 2;
    case QtWarningMsg: return 1;
    case QtCriticalMsg:
    case QtFatalMsg:
    default: return 0;
    }
}

const char *typeTag(QtMsgType t)
{
    switch (t) {
    case QtDebugMsg: return "DEBUG";
    case QtInfoMsg: return "INFO";
    case QtWarningMsg: return "WARN";
    case QtCriticalMsg: return "ERROR";
    case QtFatalMsg: return "FATAL";
    default: return "LOG";
    }
}

} // namespace

Logger &Logger::instance()
{
    static Logger s;
    return s;
}

Logger::Logger(QObject *parent)
    : QObject(parent)
{
}

void Logger::install(bool saveLog, const QString &logFile, const QString &logLevel)
{
    QMutexLocker lock(&m_mutex);
    m_saveLog = saveLog;
    m_logFile = logFile;
    m_logLevel = logLevel.isEmpty() ? QStringLiteral("Errors only") : logLevel;
    if (!m_installed) {
        m_installed = true;
        qInstallMessageHandler(&Logger::handler);
    }
    lock.unlock();
    emit saveLogChanged();
    emit logFileChanged();
    emit logLevelChanged();
    qInfo() << "M6 logger: installed saveLog=" << m_saveLog
            << "file=" << resolvedLogFile() << "level=" << m_logLevel;
}

void Logger::setSaveLog(bool v)
{
    QMutexLocker lock(&m_mutex);
    if (m_saveLog == v)
        return;
    m_saveLog = v;
    lock.unlock();
    emit saveLogChanged();
    qInfo() << "M6 logger: saveLog =" << v;
}

void Logger::setLogLevel(const QString &v)
{
    const QString nv = v.isEmpty() ? QStringLiteral("Errors only") : v;
    QMutexLocker lock(&m_mutex);
    if (m_logLevel == nv)
        return;
    m_logLevel = nv;
    lock.unlock();
    emit logLevelChanged();
    qInfo() << "M6 logger: logLevel =" << nv;
}

bool Logger::saveLog() const
{
    QMutexLocker lock(&m_mutex);
    return m_saveLog;
}

QString Logger::logFile() const
{
    QMutexLocker lock(&m_mutex);
    return m_logFile;
}

QString Logger::logLevel() const
{
    QMutexLocker lock(&m_mutex);
    return m_logLevel;
}

QString Logger::defaultLogFile() const
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return dir + QDir::separator() + QStringLiteral("vlc-redesign.log");
}

QString Logger::resolvedLogFile() const
{
    QMutexLocker lock(&m_mutex);
    if (!m_logFile.trimmed().isEmpty())
        return m_logFile;
    // NOTE: do not call defaultLogFile() under lock (no lock needed there,
    // but keep it simple and lock-free here).
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return dir + QDir::separator() + QStringLiteral("vlc-redesign.log");
}

bool Logger::passesFilter(QtMsgType type) const
{
    return typeRank(type) <= levelRank(m_logLevel);
}

void Logger::appendLine(const QString &line)
{
    const QString path = resolvedLogFile();
    QFileInfo fi(path);
    QDir().mkpath(fi.absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::Append | QIODevice::Text)) {
        fprintf(stderr, "M6 logger: cannot open %s\n", qPrintable(path));
        return;
    }
    QTextStream out(&f);
    out << line << "\n";
}

void Logger::handler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    Logger &self = Logger::instance();
    const QString line = QStringLiteral("%1 [%2] %3 (%4:%5)")
                             .arg(QDateTime::currentDateTime().toString(Qt::ISODate))
                             .arg(QString::fromLatin1(typeTag(type)))
                             .arg(msg)
                             .arg(QString::fromLatin1(ctx.file ? ctx.file : "?"))
                             .arg(ctx.line);

    // Console copy always (keeps dev builds live even when file is off).
    fprintf(stderr, "%s\n", qPrintable(line));

    QMutexLocker lock(&self.m_mutex);
    if (!self.m_saveLog)
        return;
    if (!self.passesFilter(type))
        return;
    lock.unlock();
    self.appendLine(line);
    if (type == QtFatalMsg)
        abort();
}

QString Logger::exportLogBundle(const QString &destPath)
{
    QString dest = destPath.trimmed();
    if (dest.isEmpty()) {
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        dest = dir + QDir::separator() + QStringLiteral("vlc-logbundle.txt");
    }
    QFile out(dest);
    if (!out.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qWarning() << "M6 logger: cannot write bundle to" << dest;
        return QString();
    }
    QTextStream s(&out);
    s << "VLC Redesign log bundle (M6 stub, plain-text; .zip lands later)\n";
    s << "exported: " << QDateTime::currentDateTime().toString(Qt::ISODate) << "\n";
    s << "app: " << QCoreApplication::applicationName()
      << " schema: " << QSettings(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"))
                              .value(QStringLiteral("m3/schemaVersion"), 0).toInt() << "\n";
    s << "logLevel: " << m_logLevel << " saveLog: " << (m_saveLog ? "on" : "off") << "\n";
    s << "--- log tail (" << resolvedLogFile() << ") ---\n";
    QFile log(resolvedLogFile());
    if (log.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&log);
        QStringList lines;
        while (!in.atEnd())
            lines << in.readLine();
        const int tail = qMin(200, lines.size());
        for (int i = lines.size() - tail; i < lines.size(); ++i)
            s << lines.at(i) << "\n";
        if (tail == 0)
            s << "(log file empty or unwritten)\n";
    } else {
        s << "(no log file at " << resolvedLogFile() << ")\n";
    }
    s << "--- end ---\n";
    out.close();
    qInfo() << "M6 logger: bundle exported to" << dest;
    return dest;
}

void Logger::selfTest()
{
    qDebug() << "M6 logger selftest: debug line (visible at Debug only)";
    qInfo() << "M6 logger selftest: info line (visible at Info+)";
    qWarning() << "M6 logger selftest: warning line (visible at Warnings+)";
    qCritical() << "M6 logger selftest: error line (always logged when saveLog is on)";
}
