#pragma once

#include <QMap>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

// M5 LibraryService: SQLite-backed library + playlist store (M2) with
// thumbnail LRU-200 hint cache + folder scan watcher stub.
// Schema is created on startup via ensureSchema() (called from main.cpp).
// Fixture: 15 items The_Wand_S01E01-E15; E01-E04 carry watch progress.
// Thumbnails resolve async via thumbnailReady(): cache hits emit on the
// next event loop, misses resolve after 50ms and populate the LRU (cap
// 200, oldest-first eviction). Real frame decode + disk cache lands later.
// Scan watcher stub: startScan() fakes a 20-file sweep at ~8 files/sec so
// QML can show progress; real QFileSystemWatcher + SQLite upsert lands
// later. Emits scanStarted/scanProgress/scanFinished or scanError.
class LibraryService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(double scanProgress READ scanProgress NOTIFY scanProgressChanged)
public:
    explicit LibraryService(QObject *parent = nullptr);

    // Creates media / playlists / playlist_items tables if missing.
    // Falls back to :memory: when the app-data dir is unavailable.
    // Returns true when the schema is live (false = fixture-only mode).
    Q_INVOKABLE bool ensureSchema();

    // Full DDL for the M2 schema (handy for tests / future migrations).
    Q_INVOKABLE QString schemaSql() const;

    // 15-item fixture: The_Wand_S01E01-E15, E01-E04 watched.
    Q_INVOKABLE QVariantList fixtureItems();

    // Playlist CRUD stubs (backed by SQLite when the schema is live).
    Q_INVOKABLE QVariantList playlists();
    Q_INVOKABLE bool createPlaylist(const QString &name);
    Q_INVOKABLE bool renamePlaylist(const QString &oldName, const QString &newName);
    Q_INVOKABLE bool deletePlaylist(const QString &name);

    // Thumbnail worker: LRU-200 hint cache, async via thumbnailReady().
    Q_INVOKABLE void requestThumbnail(const QString &path);
    Q_INVOKABLE int thumbnailCacheSize() const;
    Q_INVOKABLE bool isThumbnailCached(const QString &path) const;
    Q_INVOKABLE void clearThumbnailCache();

    // Folder scan watcher stub: async sweep with progress signals.
    Q_INVOKABLE void startScan(const QString &folder);
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE bool scanning() const;
    Q_INVOKABLE double scanProgress() const;

signals:
    void thumbnailReady(const QString &path, const QString &hint);
    void playlistsChanged();
    void scanningChanged();
    void scanProgressChanged();
    void scanStarted(const QString &folder);
    void scanProgress(const QString &folder, int done, int total);
    void scanFinished(const QString &folder, int count);
    void scanError(const QString &folder, const QString &message);

private:
    void storeThumb(const QString &path, const QString &hint);
    void touchThumb(const QString &path);

    bool m_ready = false;

    // M5 thumbnail LRU-200: map + MRU-last order list (cap enforced).
    static const int kThumbCacheCap = 200;
    QMap<QString, QString> m_thumbCache;
    QStringList m_thumbOrder;

    // M5 scan watcher stub state (driven by QTimers, no threads yet).
    bool m_scanning = false;
    double m_scanProgressValue = 0.0;
    int m_scanDone = 0;
    int m_scanTotal = 20;
    QString m_scanFolder;
};
