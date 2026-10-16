#include "libraryservice.h"

#include <QDebug>
#include <QDir>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QTimer>
#include <QVariantMap>

namespace {

const char *kMediaTable = R"SQL(
CREATE TABLE IF NOT EXISTS media (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  path      TEXT UNIQUE NOT NULL,
  title     TEXT NOT NULL DEFAULT '',
  show      TEXT NOT NULL DEFAULT '',
  season    INTEGER NOT NULL DEFAULT 1,
  episode   INTEGER NOT NULL DEFAULT 0,
  duration  INTEGER NOT NULL DEFAULT 0,
  progress  REAL NOT NULL DEFAULT 0,
  thumbnail TEXT NOT NULL DEFAULT ''
))SQL";

const char *kPlaylistsTable = R"SQL(
CREATE TABLE IF NOT EXISTS playlists (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT UNIQUE NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
))SQL";

const char *kPlaylistItemsTable = R"SQL(
CREATE TABLE IF NOT EXISTS playlist_items (
  playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  media_id    INTEGER NOT NULL REFERENCES media(id) ON DELETE CASCADE,
  position    INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (playlist_id, media_id)
))SQL";

double watchedProgress(int episode)
{
    // E01-E04 read as watched in Player-1.png (orange underline).
    switch (episode) {
    case 1: return 1.0;
    case 2: return 0.92;
    case 3: return 0.88;
    case 4: return 0.96;
    default: return 0.0;
    }
}

} // namespace

LibraryService::LibraryService(QObject *parent)
    : QObject(parent)
{
}

QString LibraryService::schemaSql() const
{
    return QString::fromLatin1(kMediaTable) + QStringLiteral("\n")
        + QString::fromLatin1(kPlaylistsTable) + QStringLiteral("\n")
        + QString::fromLatin1(kPlaylistItemsTable);
}

bool LibraryService::ensureSchema()
{
    if (m_ready)
        return true;

    const QString dir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!dir.isEmpty())
        QDir().mkpath(dir);

    QSqlDatabase db = QSqlDatabase::contains(QStringLiteral("vlc-library"))
        ? QSqlDatabase::database(QStringLiteral("vlc-library"))
        : QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"),
                                    QStringLiteral("vlc-library"));
    db.setDatabaseName(dir.isEmpty() ? QStringLiteral(":memory:")
                                     : dir + QStringLiteral("/vlc-library.db"));
    if (!db.open()) {
        qWarning() << "M2 LibraryService: sqlite open failed:"
                   << db.lastError().text() << "(fixture-only mode)";
        return false;
    }

    QSqlQuery q(db);
    const char *ddls[] = {kMediaTable, kPlaylistsTable, kPlaylistItemsTable};
    for (const char *ddl : ddls) {
        if (!q.exec(QString::fromLatin1(ddl))) {
            qWarning() << "M2 LibraryService: schema exec failed:"
                       << q.lastError().text();
            return false;
        }
    }
    m_ready = true;
    qInfo() << "M2 LibraryService: schema ready at" << db.databaseName();

    // Seed the M1 drawer playlists on first run.
    QSqlQuery count(db);
    if (count.exec(QStringLiteral("SELECT COUNT(*) FROM playlists"))
        && count.next() && count.value(0).toInt() == 0) {
        createPlaylist(QStringLiteral("Cool Songs"));
        createPlaylist(QStringLiteral("Anime to Watch"));
    }
    return true;
}

QVariantList LibraryService::fixtureItems()
{
    QVariantList items;
    items.reserve(15);
    for (int ep = 1; ep <= 15; ++ep) {
        const QString num = QString::asprintf("%02d", ep);
        const QString fileName =
            QStringLiteral("The_Wand_S01E%1.mp4").arg(num);
        QVariantMap m;
        m.insert(QStringLiteral("path"),
                 QStringLiteral("/videos/The_Wand/S01/") + fileName);
        m.insert(QStringLiteral("fileName"), fileName);
        m.insert(QStringLiteral("title"),
                 QStringLiteral("The Wand S01E%1").arg(num));
        m.insert(QStringLiteral("show"), QStringLiteral("The Wand"));
        m.insert(QStringLiteral("season"), 1);
        m.insert(QStringLiteral("episode"), ep);
        m.insert(QStringLiteral("duration"), 1540); // 00:25:40 demo length
        m.insert(QStringLiteral("progress"), watchedProgress(ep));
        items.append(m);

        // Persist the fixture row when the schema is live (idempotent).
        if (m_ready) {
            QSqlDatabase db = QSqlDatabase::database(QStringLiteral("vlc-library"));
            QSqlQuery ins(db);
            ins.prepare(QStringLiteral(
                "INSERT OR IGNORE INTO media"
                " (path, title, show, season, episode, duration, progress)"
                " VALUES (:path, :title, :show, :season, :episode, :duration, :progress)"));
            ins.bindValue(QStringLiteral(":path"), m.value(QStringLiteral("path")));
            ins.bindValue(QStringLiteral(":title"), m.value(QStringLiteral("title")));
            ins.bindValue(QStringLiteral(":show"), m.value(QStringLiteral("show")));
            ins.bindValue(QStringLiteral(":season"), m.value(QStringLiteral("season")));
            ins.bindValue(QStringLiteral(":episode"), m.value(QStringLiteral("episode")));
            ins.bindValue(QStringLiteral(":duration"), m.value(QStringLiteral("duration")));
            ins.bindValue(QStringLiteral(":progress"), m.value(QStringLiteral("progress")));
            if (!ins.exec())
                qWarning() << "M2 LibraryService: fixture upsert failed:"
                           << ins.lastError().text();
        }
    }
    return items;
}

QVariantList LibraryService::playlists()
{
    QVariantList out;
    if (m_ready) {
        QSqlDatabase db = QSqlDatabase::database(QStringLiteral("vlc-library"));
        QSqlQuery q(db);
        if (q.exec(QStringLiteral("SELECT name FROM playlists ORDER BY id"))) {
            while (q.next())
                out.append(q.value(0).toString());
        } else {
            qWarning() << "M2 LibraryService: playlists query failed:"
                       << q.lastError().text();
        }
    }
    if (out.isEmpty()) {
        // Fixture fallback (also covers fixture-only mode).
        out.append(QStringLiteral("Cool Songs"));
        out.append(QStringLiteral("Anime to Watch"));
    }
    return out;
}

bool LibraryService::createPlaylist(const QString &name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        qWarning() << "M2 LibraryService: createPlaylist refused (empty name)";
        return false;
    }
    if (m_ready) {
        QSqlDatabase db = QSqlDatabase::database(QStringLiteral("vlc-library"));
        QSqlQuery q(db);
        q.prepare(QStringLiteral("INSERT OR IGNORE INTO playlists (name) VALUES (:name)"));
        q.bindValue(QStringLiteral(":name"), trimmed);
        if (!q.exec()) {
            qWarning() << "M2 LibraryService: createPlaylist failed:"
                       << q.lastError().text();
            return false;
        }
    }
    qInfo() << "M2 playlist created (stub):" << trimmed;
    emit playlistsChanged();
    return true;
}

bool LibraryService::renamePlaylist(const QString &oldName, const QString &newName)
{
    const QString to = newName.trimmed();
    if (oldName.trimmed().isEmpty() || to.isEmpty())
        return false;
    if (m_ready) {
        QSqlDatabase db = QSqlDatabase::database(QStringLiteral("vlc-library"));
        QSqlQuery q(db);
        q.prepare(QStringLiteral("UPDATE OR IGNORE playlists SET name=:to WHERE name=:from"));
        q.bindValue(QStringLiteral(":to"), to);
        q.bindValue(QStringLiteral(":from"), oldName.trimmed());
        if (!q.exec()) {
            qWarning() << "M2 LibraryService: renamePlaylist failed:"
                       << q.lastError().text();
            return false;
        }
    }
    qInfo() << "M2 playlist renamed (stub):" << oldName << "->" << to;
    emit playlistsChanged();
    return true;
}

bool LibraryService::deletePlaylist(const QString &name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty())
        return false;
    if (m_ready) {
        QSqlDatabase db = QSqlDatabase::database(QStringLiteral("vlc-library"));
        QSqlQuery items(db);
        items.prepare(QStringLiteral(
            "DELETE FROM playlist_items WHERE playlist_id ="
            " (SELECT id FROM playlists WHERE name=:name)"));
        items.bindValue(QStringLiteral(":name"), trimmed);
        items.exec();
        QSqlQuery q(db);
        q.prepare(QStringLiteral("DELETE FROM playlists WHERE name=:name"));
        q.bindValue(QStringLiteral(":name"), trimmed);
        if (!q.exec()) {
            qWarning() << "M2 LibraryService: deletePlaylist failed:"
                       << q.lastError().text();
            return false;
        }
    }
    qInfo() << "M2 playlist deleted (stub):" << trimmed;
    emit playlistsChanged();
    return true;
}

void LibraryService::requestThumbnail(const QString &path)
{
    // M5 LRU-200: cache hits emit on the next loop (still async, no C++
    // hop cost); misses resolve after 50ms and populate the LRU. Real
    // frame decode + SQLite disk cache lands later; the 50ms delay keeps
    // QML virtualized and non-blocking at 60fps @1k rows.
    if (path.isEmpty())
        return;
    if (m_thumbCache.contains(path)) {
        touchThumb(path);
        const QString hint = m_thumbCache.value(path);
        QTimer::singleShot(0, this, [this, path, hint]() {
            emit thumbnailReady(path, hint);
        });
        return;
    }
    QTimer::singleShot(50, this, [this, path]() {
        // Deterministic hint stub (QML hintFor uses the same palette
        // family; exact match is not required for the placeholder).
        static const char *kHints[] = {
            "#D37918", "#B7C82E", "#3FB950", "#58A6FF",
            "#A371F7", "#F778BA", "#FF7B72", "#E08A2E",
        };
        uint h = 0;
        for (QChar c : path)
            h = h * 31 + uint(c.unicode());
        const QString hint = QString::fromLatin1(kHints[h % 8]);
        storeThumb(path, hint);
        qInfo() << "M5 thumbnail worker:" << path << hint
                << "(cache" << m_thumbOrder.size() << "/" << kThumbCacheCap << ")";
        emit thumbnailReady(path, hint);
    });
}

int LibraryService::thumbnailCacheSize() const
{
    return m_thumbOrder.size();
}

bool LibraryService::isThumbnailCached(const QString &path) const
{
    return m_thumbCache.contains(path);
}

void LibraryService::clearThumbnailCache()
{
    m_thumbCache.clear();
    m_thumbOrder.clear();
    qInfo() << "M5 thumbnail cache cleared (stub)";
}

void LibraryService::startScan(const QString &folder)
{
    // Scan watcher stub: fake a 20-file sweep at ~8 files/sec so QML can
    // show determinate progress. Real QFileSystemWatcher + SQLite upsert
    // (with thumbnails + duration probe) lands after M5.
    if (m_scanning) {
        qInfo() << "M5 scan watcher: already scanning" << m_scanFolder;
        return;
    }
    const QString root = folder.trimmed().isEmpty() ? QStringLiteral("/videos")
                                                    : folder.trimmed();
    m_scanning = true;
    m_scanFolder = root;
    m_scanDone = 0;
    m_scanTotal = 20;
    m_scanProgressValue = 0.0;
    emit scanningChanged();
    emit scanProgressChanged();
    emit scanStarted(root);
    qInfo() << "M5 scan watcher started (stub):" << root;
    QTimer *pump = new QTimer(this);
    pump->setInterval(120);
    connect(pump, &QTimer::timeout, this, [this, pump]() {
        if (!m_scanning) {
            pump->stop();
            pump->deleteLater();
            return;
        }
        ++m_scanDone;
        m_scanProgressValue = double(m_scanDone) / double(m_scanTotal);
        emit scanProgressChanged();
        emit scanProgress(m_scanFolder, m_scanDone, m_scanTotal);
        if (m_scanDone >= m_scanTotal) {
            pump->stop();
            pump->deleteLater();
            m_scanning = false;
            m_scanProgressValue = 1.0;
            emit scanningChanged();
            emit scanProgressChanged();
            emit scanFinished(m_scanFolder, m_scanTotal);
            qInfo() << "M5 scan watcher finished (stub):" << m_scanFolder
                    << m_scanTotal << "files";
        }
    });
    pump->start();
}

void LibraryService::stopScan()
{
    if (!m_scanning)
        return;
    m_scanning = false;
    m_scanProgressValue = 0.0;
    emit scanningChanged();
    emit scanProgressChanged();
    qInfo() << "M5 scan watcher stopped (stub):" << m_scanFolder;
}

bool LibraryService::scanning() const
{
    return m_scanning;
}

double LibraryService::scanProgress() const
{
    return m_scanProgressValue;
}

void LibraryService::storeThumb(const QString &path, const QString &hint)
{
    if (!m_thumbCache.contains(path) && m_thumbOrder.size() >= kThumbCacheCap) {
        const QString oldest = m_thumbOrder.takeFirst();
        m_thumbCache.remove(oldest);
        qInfo() << "M5 thumbnail LRU evict:" << oldest;
    }
    m_thumbCache.insert(path, hint);
    touchThumb(path);
}

void LibraryService::touchThumb(const QString &path)
{
    m_thumbOrder.removeAll(path);
    m_thumbOrder.append(path);
}
