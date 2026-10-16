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

    Q_INVOKABLE double eqBand(int index) const;
    Q_INVOKABLE void setEqBand(int index, double dB);

    // Live libVLC mapping stubs (M4 wires the real engine).
    Q_INVOKABLE void applyEqualizer();
    Q_INVOKABLE void applySpuDelay();
    Q_INVOKABLE void applyVideoAdjust();
    Q_INVOKABLE void applyAudioFilters();

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

    int m_schemaVersion = 4;
};
