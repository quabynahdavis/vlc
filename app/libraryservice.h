#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

// M2 LibraryService stub: SQLite-backed library + playlist store.
// Schema is created on startup via ensureSchema() (called from main.cpp).
// Fixture: 15 items The_Wand_S01E01-E15; E01-E04 carry watch progress.
// Thumbnail generation is async-by-design: requestThumbnail() emits
// thumbnailReady() later (currently a timed stub; real decode lands later).
class LibraryService : public QObject
{
    Q_OBJECT
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

    // Thumbnail worker stub: completes async via thumbnailReady().
    Q_INVOKABLE void requestThumbnail(const QString &path);

signals:
    void thumbnailReady(const QString &path, const QString &hint);
    void playlistsChanged();

private:
    bool m_ready = false;
};
