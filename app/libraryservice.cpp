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
    // Async-by-design stub: real frame decode + disk cache lands later.
    // Resolve with a short delay so QML stays virtualized and non-blocking.
    QTimer::singleShot(50, this, [this, path]() {
        qInfo() << "M2 thumbnail worker (stub):" << path;
        emit thumbnailReady(path, QStringLiteral("#D37918"));
    });
}
