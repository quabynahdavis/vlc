#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariant>

// M3 SettingsStore stub: QSettings-backed, namespaced keys, migratable.
// Lives as a QML context property (`SettingsStore`) like LibraryService.
// All setters persist via QSettings ("VLC", "VLC Redesign") and log the
// change; live libVLC application (equalizer / spu delay / video adjust)
// lands after M3 — the apply*() stubs below only qInfo() the intent so
// QML stays live-bound without a player engine yet.
// M5 adds lowPowerMode (Performance page): when ON, Theme.reduceEffects is
// bound true and ThumbnailCard skips Canvas doodles/gradients to hold
// 60fps on weak GPUs. Schema v5 migrates the new key with default OFF.
// M6 adds telemetryEnabled (Privacy page, default OFF — telemetry stays
// opt-in), updateAvailable/updateVersion (auto-update stub), and
// exportLogBundle() (delegates to Logger). Schema v6 migrates the new keys.
// M8 fix pass: fills the remaining Global Settings pages (playback speed /
// loop / resume, video renderer / HDR / deinterlace / aspect, network cache /
// proxy, performance threads, recording path / format, privacy watch-history)
// and adds appearance.titleBar (Custom | System, default Custom). New keys
// live under the m8/ namespace; schemaVersion stays 7 so the M7 mini-player
// schema remains intact (fresh keys read back at their defaults).
class SettingsStore : public QObject
{
    Q_OBJECT

    // Appearance / startup / diagnostics (Global Settings modal).
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(QString accentColor READ accentColor WRITE setAccentColor NOTIFY accentColorChanged)
    Q_PROPERTY(QString iconPack READ iconPack WRITE setIconPack NOTIFY iconPackChanged)
    Q_PROPERTY(bool showConfirmDialogs READ showConfirmDialogs WRITE setShowConfirmDialogs NOTIFY showConfirmDialogsChanged)
    Q_PROPERTY(bool checkUpdates READ checkUpdates WRITE setCheckUpdates NOTIFY checkUpdatesChanged)
    Q_PROPERTY(bool developerMode READ developerMode WRITE setDeveloperMode NOTIFY developerModeChanged)
    Q_PROPERTY(bool saveLog READ saveLog WRITE setSaveLog NOTIFY saveLogChanged)
    Q_PROPERTY(QString logFile READ logFile WRITE setLogFile NOTIFY logFileChanged)
    Q_PROPERTY(QString logLevel READ logLevel WRITE setLogLevel NOTIFY logLevelChanged)
    Q_PROPERTY(bool lowPowerMode READ lowPowerMode WRITE setLowPowerMode NOTIFY lowPowerModeChanged)
    // M6: privacy opt-in (default OFF) + auto-update stub state.
    Q_PROPERTY(bool telemetryEnabled READ telemetryEnabled WRITE setTelemetryEnabled NOTIFY telemetryEnabledChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString updateVersion READ updateVersion NOTIFY updateVersionChanged)
    // M7 mini-player (appearance.miniPlayer): master + 4 triggers + pin + geometry.
    Q_PROPERTY(bool miniPlayerEnabled READ miniPlayerEnabled WRITE setMiniPlayerEnabled NOTIFY miniPlayerEnabledChanged)
    Q_PROPERTY(bool miniPlayerTriggerManual READ miniPlayerTriggerManual WRITE setMiniPlayerTriggerManual NOTIFY miniPlayerTriggerManualChanged)
    Q_PROPERTY(bool miniPlayerTriggerMinimize READ miniPlayerTriggerMinimize WRITE setMiniPlayerTriggerMinimize NOTIFY miniPlayerTriggerMinimizeChanged)
    Q_PROPERTY(bool miniPlayerTriggerNavigate READ miniPlayerTriggerNavigate WRITE setMiniPlayerTriggerNavigate NOTIFY miniPlayerTriggerNavigateChanged)
    Q_PROPERTY(bool miniPlayerTriggerCloseToMini READ miniPlayerTriggerCloseToMini WRITE setMiniPlayerTriggerCloseToMini NOTIFY miniPlayerTriggerCloseToMiniChanged)
    Q_PROPERTY(bool closeToMini READ closeToMini WRITE setCloseToMini NOTIFY closeToMiniChanged)
    Q_PROPERTY(bool miniPlayerAlwaysOnTop READ miniPlayerAlwaysOnTop WRITE setMiniPlayerAlwaysOnTop NOTIFY miniPlayerAlwaysOnTopChanged)
    Q_PROPERTY(int miniPlayerWidth READ miniPlayerWidth WRITE setMiniPlayerWidth NOTIFY miniPlayerWidthChanged)
    Q_PROPERTY(int miniPlayerHeight READ miniPlayerHeight WRITE setMiniPlayerHeight NOTIFY miniPlayerHeightChanged)
    Q_PROPERTY(int miniPlayerX READ miniPlayerX WRITE setMiniPlayerX NOTIFY miniPlayerXChanged)
    Q_PROPERTY(int miniPlayerY READ miniPlayerY WRITE setMiniPlayerY NOTIFY miniPlayerYChanged)

    // M8 fix pass: remaining Global Settings pages (m8/ keys, schema v7).
    Q_PROPERTY(double playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(QString loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)
    Q_PROPERTY(bool resumePlayback READ resumePlayback WRITE setResumePlayback NOTIFY resumePlaybackChanged)
    Q_PROPERTY(QString videoRenderer READ videoRenderer WRITE setVideoRenderer NOTIFY videoRendererChanged)
    Q_PROPERTY(bool hdrPassthrough READ hdrPassthrough WRITE setHdrPassthrough NOTIFY hdrPassthroughChanged)
    Q_PROPERTY(QString deinterlaceMode READ deinterlaceMode WRITE setDeinterlaceMode NOTIFY deinterlaceModeChanged)
    Q_PROPERTY(QString aspectRatio READ aspectRatio WRITE setAspectRatio NOTIFY aspectRatioChanged)
    Q_PROPERTY(QString titleBar READ titleBar WRITE setTitleBar NOTIFY titleBarChanged)
    Q_PROPERTY(QString networkCache READ networkCache WRITE setNetworkCache NOTIFY networkCacheChanged)
    Q_PROPERTY(QString proxyType READ proxyType WRITE setProxyType NOTIFY proxyTypeChanged)
    Q_PROPERTY(QString proxyHost READ proxyHost WRITE setProxyHost NOTIFY proxyHostChanged)
    Q_PROPERTY(QString threadCount READ threadCount WRITE setThreadCount NOTIFY threadCountChanged)
    Q_PROPERTY(QString recordPath READ recordPath WRITE setRecordPath NOTIFY recordPathChanged)
    Q_PROPERTY(QString recordFormat READ recordFormat WRITE setRecordFormat NOTIFY recordFormatChanged)
    Q_PROPERTY(bool watchHistory READ watchHistory WRITE setWatchHistory NOTIFY watchHistoryChanged)

    // Audio defaults (EQ + spatial rows).
    Q_PROPERTY(bool eqEnabled READ eqEnabled WRITE setEqEnabled NOTIFY eqEnabledChanged)
    Q_PROPERTY(QString eqPreset READ eqPreset WRITE setEqPreset NOTIFY eqPresetChanged)
    Q_PROPERTY(QVariantList eqBands READ eqBands NOTIFY eqBandsChanged)
    Q_PROPERTY(bool twoPass READ twoPass WRITE setTwoPass NOTIFY twoPassChanged)
    Q_PROPERTY(bool spatialAudio READ spatialAudio WRITE setSpatialAudio NOTIFY spatialAudioChanged)
    Q_PROPERTY(QString spatialMode READ spatialMode WRITE setSpatialMode NOTIFY spatialModeChanged)
    Q_PROPERTY(bool stereoWidening READ stereoWidening WRITE setStereoWidening NOTIFY stereoWideningChanged)

    // Subtitles panel.
    Q_PROPERTY(int subTrack READ subTrack WRITE setSubTrack NOTIFY subTrackChanged)
    Q_PROPERTY(QString subLanguage READ subLanguage WRITE setSubLanguage NOTIFY subLanguageChanged)
    Q_PROPERTY(double subDelay READ subDelay WRITE setSubDelay NOTIFY subDelayChanged)
    Q_PROPERTY(double subSpeed READ subSpeed WRITE setSubSpeed NOTIFY subSpeedChanged)
    Q_PROPERTY(double subDurationFactor READ subDurationFactor WRITE setSubDurationFactor NOTIFY subDurationFactorChanged)
    Q_PROPERTY(bool embeddedSubFormat READ embeddedSubFormat WRITE setEmbeddedSubFormat NOTIFY embeddedSubFormatChanged)
    Q_PROPERTY(QString subFont READ subFont WRITE setSubFont NOTIFY subFontChanged)
    Q_PROPERTY(QString textColor READ textColor WRITE setTextColor NOTIFY textColorChanged)
    Q_PROPERTY(QString outlineColor READ outlineColor WRITE setOutlineColor NOTIFY outlineColorChanged)

    Q_PROPERTY(int schemaVersion READ schemaVersion NOTIFY schemaVersionChanged)

public:
    explicit SettingsStore(QObject *parent = nullptr);

    // Generic namespaced store for the Effects dock
    // (keys like "effects/compressor/threshold", "video/hue", ...).
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &fallback = QVariant()) const;
    Q_INVOKABLE void setValue(const QString &key, const QVariant &val);
    Q_INVOKABLE void resetToDefaults();

    // Static option lists for QML dropdowns / swatches / faders.
    Q_INVOKABLE QStringList accentPalette() const;
    Q_INVOKABLE QStringList eqBandNames() const;
    Q_INVOKABLE QStringList languageOptions() const;
    Q_INVOKABLE QStringList themeOptions() const;
    Q_INVOKABLE QStringList iconPackOptions() const;
    Q_INVOKABLE QStringList eqPresetOptions() const;
    Q_INVOKABLE QStringList spatialModeOptions() const;
    Q_INVOKABLE QStringList logLevelOptions() const;
    Q_INVOKABLE QStringList playbackSpeedOptions() const;
    Q_INVOKABLE QStringList loopModeOptions() const;
    Q_INVOKABLE QStringList rendererOptions() const;
    Q_INVOKABLE QStringList deinterlaceOptions() const;
    Q_INVOKABLE QStringList aspectRatioOptions() const;
    Q_INVOKABLE QStringList titleBarOptions() const;
    Q_INVOKABLE QStringList networkCacheOptions() const;
    Q_INVOKABLE QStringList proxyTypeOptions() const;
    Q_INVOKABLE QStringList threadCountOptions() const;
    Q_INVOKABLE QStringList recordFormatOptions() const;

    Q_INVOKABLE double eqBand(int index) const;
    Q_INVOKABLE void setEqBand(int index, double dB);

    // Live libVLC mapping stubs (M4 wires the real engine).
    Q_INVOKABLE void applyEqualizer();
    Q_INVOKABLE void applySpuDelay();
    Q_INVOKABLE void applyVideoAdjust();
    Q_INVOKABLE void applyAudioFilters();

    // M6 diagnostics: export a log bundle via Logger (returns bundle path).
    Q_INVOKABLE QString exportLogBundle(const QString &destPath = QString());
    // M6 auto-update stub: consults checkUpdates, then reports "up to date".
    // Real feed fetch + signature verify + installer relaunch is a follow-up.
    Q_INVOKABLE void checkForUpdates();
    // M7: persist mini-player geometry in one round-trip (sizeMemory).
    Q_INVOKABLE void saveMiniPlayerGeometry(int w, int h, int x, int y);

    // Typed getters/setters.
    QString language() const;
    void setLanguage(const QString &v);
    QString themeMode() const;
    void setThemeMode(const QString &v);
    QString accentColor() const;
    void setAccentColor(const QString &v);
    QString iconPack() const;
    void setIconPack(const QString &v);
    bool showConfirmDialogs() const;
    void setShowConfirmDialogs(bool v);
    bool checkUpdates() const;
    void setCheckUpdates(bool v);
    bool developerMode() const;
    void setDeveloperMode(bool v);
    bool saveLog() const;
    void setSaveLog(bool v);
    QString logFile() const;
    void setLogFile(const QString &v);
    QString logLevel() const;
    void setLogLevel(const QString &v);
    bool lowPowerMode() const;
    void setLowPowerMode(bool v);

    bool telemetryEnabled() const;
    void setTelemetryEnabled(bool v);

    bool updateAvailable() const;
    QString updateVersion() const;

    // M7 mini-player typed accessors (all defaults ON per 04-mini-player.md).
    bool miniPlayerEnabled() const;
    void setMiniPlayerEnabled(bool v);
    bool miniPlayerTriggerManual() const;
    void setMiniPlayerTriggerManual(bool v);
    bool miniPlayerTriggerMinimize() const;
    void setMiniPlayerTriggerMinimize(bool v);
    bool miniPlayerTriggerNavigate() const;
    void setMiniPlayerTriggerNavigate(bool v);
    bool miniPlayerTriggerCloseToMini() const;
    void setMiniPlayerTriggerCloseToMini(bool v);
    bool closeToMini() const;
    void setCloseToMini(bool v);
    bool miniPlayerAlwaysOnTop() const;
    void setMiniPlayerAlwaysOnTop(bool v);
    int miniPlayerWidth() const;
    void setMiniPlayerWidth(int v);
    int miniPlayerHeight() const;
    void setMiniPlayerHeight(int v);
    int miniPlayerX() const;
    void setMiniPlayerX(int v);
    int miniPlayerY() const;
    void setMiniPlayerY(int v);

    // M8 fix pass typed accessors.
    double playbackSpeed() const;
    void setPlaybackSpeed(double v);
    QString loopMode() const;
    void setLoopMode(const QString &v);
    bool resumePlayback() const;
    void setResumePlayback(bool v);
    QString videoRenderer() const;
    void setVideoRenderer(const QString &v);
    bool hdrPassthrough() const;
    void setHdrPassthrough(bool v);
    QString deinterlaceMode() const;
    void setDeinterlaceMode(const QString &v);
    QString aspectRatio() const;
    void setAspectRatio(const QString &v);
    QString titleBar() const;
    void setTitleBar(const QString &v);
    QString networkCache() const;
    void setNetworkCache(const QString &v);
    QString proxyType() const;
    void setProxyType(const QString &v);
    QString proxyHost() const;
    void setProxyHost(const QString &v);
    QString threadCount() const;
    void setThreadCount(const QString &v);
    QString recordPath() const;
    void setRecordPath(const QString &v);
    QString recordFormat() const;
    void setRecordFormat(const QString &v);
    bool watchHistory() const;
    void setWatchHistory(bool v);

    bool eqEnabled() const;
    void setEqEnabled(bool v);
    QString eqPreset() const;
    void setEqPreset(const QString &v);
    QVariantList eqBands() const;
    bool twoPass() const;
    void setTwoPass(bool v);
    bool spatialAudio() const;
    void setSpatialAudio(bool v);
    QString spatialMode() const;
    void setSpatialMode(const QString &v);
    bool stereoWidening() const;
    void setStereoWidening(bool v);

    int subTrack() const;
    void setSubTrack(int v);
    QString subLanguage() const;
    void setSubLanguage(const QString &v);
    double subDelay() const;
    void setSubDelay(double v);
    double subSpeed() const;
    void setSubSpeed(double v);
    double subDurationFactor() const;
    void setSubDurationFactor(double v);
    bool embeddedSubFormat() const;
    void setEmbeddedSubFormat(bool v);
    QString subFont() const;
    void setSubFont(const QString &v);
    QString textColor() const;
    void setTextColor(const QString &v);
    QString outlineColor() const;
    void setOutlineColor(const QString &v);

    int schemaVersion() const;

signals:
    void languageChanged();
    void themeModeChanged();
    void accentColorChanged();
    void iconPackChanged();
    void showConfirmDialogsChanged();
    void checkUpdatesChanged();
    void developerModeChanged();
    void saveLogChanged();
    void logFileChanged();
    void logLevelChanged();
    void lowPowerModeChanged();
    void telemetryEnabledChanged();
    void updateAvailableChanged();
    void updateVersionChanged();
    // M7 mini-player notifications (closeToMini mirrors triggerCloseToMini).
    void miniPlayerEnabledChanged();
    void miniPlayerTriggerManualChanged();
    void miniPlayerTriggerMinimizeChanged();
    void miniPlayerTriggerNavigateChanged();
    void miniPlayerTriggerCloseToMiniChanged();
    void closeToMiniChanged();
    void miniPlayerAlwaysOnTopChanged();
    void miniPlayerWidthChanged();
    void miniPlayerHeightChanged();
    void miniPlayerXChanged();
    void miniPlayerYChanged();
    // M8 fix pass notifications.
    void playbackSpeedChanged();
    void loopModeChanged();
    void resumePlaybackChanged();
    void videoRendererChanged();
    void hdrPassthroughChanged();
    void deinterlaceModeChanged();
    void aspectRatioChanged();
    void titleBarChanged();
    void networkCacheChanged();
    void proxyTypeChanged();
    void proxyHostChanged();
    void threadCountChanged();
    void recordPathChanged();
    void recordFormatChanged();
    void watchHistoryChanged();
    void eqEnabledChanged();
    void eqPresetChanged();
    void eqBandsChanged();
    void twoPassChanged();
    void spatialAudioChanged();
    void spatialModeChanged();
    void stereoWideningChanged();
    void subTrackChanged();
    void subLanguageChanged();
    void subDelayChanged();
    void subSpeedChanged();
    void subDurationFactorChanged();
    void embeddedSubFormatChanged();
    void subFontChanged();
    void textColorChanged();
    void outlineColorChanged();
    void schemaVersionChanged();
    void settingChanged(const QString &key, const QVariant &val);

private:
    void loadAll();
    void migrateIfNeeded();
    void put(const QString &key, const QVariant &val);

    QString m_language = QStringLiteral("English");
    QString m_themeMode = QStringLiteral("Dark");
    QString m_accentColor = QStringLiteral("#D37918");
    QString m_iconPack = QStringLiteral("Two-tone");
    bool m_showConfirmDialogs = false;
    bool m_checkUpdates = false;
    bool m_developerMode = false;
    bool m_saveLog = true;
    QString m_logFile;
    QString m_logLevel = QStringLiteral("Errors only");
    bool m_lowPowerMode = false;
    // M6: telemetry stays OFF unless the user opts in on the Privacy page.
    bool m_telemetryEnabled = false;
    // M6 auto-update stub state (no update known until checkForUpdates()).
    bool m_updateAvailable = false;
    QString m_updateVersion;

    bool m_eqEnabled = false;
    QString m_eqPreset = QStringLiteral("None");
    QVariantList m_eqBands;
    bool m_twoPass = false;
    bool m_spatialAudio = false;
    QString m_spatialMode = QStringLiteral("Headphone virtualization");
    bool m_stereoWidening = false;

    int m_subTrack = 1;
    QString m_subLanguage = QStringLiteral("English");
    double m_subDelay = -4.0;
    double m_subSpeed = 1.0;
    double m_subDurationFactor = 0.0;
    bool m_embeddedSubFormat = false;
    QString m_subFont = QStringLiteral("Inter");
    QString m_textColor = QStringLiteral("#B8B8B8");
    QString m_outlineColor = QStringLiteral("#0C0C0C");

    // M7 mini-player state (appearance.miniPlayer, all defaults ON).
    bool m_miniPlayerEnabled = true;
    bool m_miniTriggerManual = true;
    bool m_miniTriggerMinimize = true;
    bool m_miniTriggerNavigate = true;
    bool m_miniTriggerCloseToMini = true;
    bool m_miniAlwaysOnTop = true;
    int m_miniW = 360;
    int m_miniH = 140;
    int m_miniX = -1;
    int m_miniY = -1;

    // M8 fix pass state (m8/ keys; schema version stays 7).
    double m_playbackSpeed = 1.0;
    QString m_loopMode = QStringLiteral("Off");
    bool m_resumePlayback = true;
    QString m_videoRenderer = QStringLiteral("Automatic");
    bool m_hdrPassthrough = false;
    QString m_deinterlaceMode = QStringLiteral("Off");
    QString m_aspectRatio = QStringLiteral("Default");
    QString m_titleBar = QStringLiteral("Custom");
    QString m_networkCache = QStringLiteral("3000 ms");
    QString m_proxyType = QStringLiteral("None");
    QString m_proxyHost;
    QString m_threadCount = QStringLiteral("Auto");
    QString m_recordPath;
    QString m_recordFormat = QStringLiteral("mp4");
    bool m_watchHistory = true;

    int m_schemaVersion = 7;
};
