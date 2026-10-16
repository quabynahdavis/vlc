#include "settingsstore.h"

#include "logger.h"

#include <QDebug>
#include <QSettings>

namespace {

const int kSchemaVersion = 6;

QVariantList defaultEqBands()
{
    // Preamp 12.0 dB per Settings-audio.png, 10 bands flat at 0.0 dB.
    return QVariantList{12.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
}

} // namespace

SettingsStore::SettingsStore(QObject *parent)
    : QObject(parent)
    , m_eqBands(defaultEqBands())
{
    migrateIfNeeded();
    loadAll();
}

QVariant SettingsStore::value(const QString &key, const QVariant &fallback) const
{
    QSettings s(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"));
    return s.value(QStringLiteral("m3/") + key, fallback);
}

void SettingsStore::setValue(const QString &key, const QVariant &val)
{
    put(QStringLiteral("m3/") + key, val);
    qInfo() << "M3 settings:" << key << "=" << val << "(stub: persisted via QSettings)";
    emit settingChanged(key, val);
}

void SettingsStore::resetToDefaults()
{
    QSettings s(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"));
    s.beginGroup(QStringLiteral("m3"));
    s.remove(QStringLiteral(""));
    s.endGroup();
    m_language = QStringLiteral("English");
    m_themeMode = QStringLiteral("Dark");
    m_accentColor = QStringLiteral("#D37918");
    m_iconPack = QStringLiteral("Two-tone");
    m_showConfirmDialogs = false;
    m_checkUpdates = false;
    m_developerMode = false;
    m_saveLog = true;
    m_logFile.clear();
    m_logLevel = QStringLiteral("Errors only");
    m_lowPowerMode = false;
    m_telemetryEnabled = false;
    m_updateAvailable = false;
    m_updateVersion.clear();
    m_eqEnabled = false;
    m_eqPreset = QStringLiteral("None");
    m_eqBands = defaultEqBands();
    m_twoPass = false;
    m_spatialAudio = false;
    m_spatialMode = QStringLiteral("Headphone virtualization");
    m_stereoWidening = false;
    m_subTrack = 1;
    m_subLanguage = QStringLiteral("English");
    m_subDelay = -4.0;
    m_subSpeed = 1.0;
    m_subDurationFactor = 0.0;
    m_embeddedSubFormat = false;
    m_subFont = QStringLiteral("Inter");
    m_textColor = QStringLiteral("#B8B8B8");
    m_outlineColor = QStringLiteral("#0C0C0C");
    emit languageChanged();
    emit themeModeChanged();
    emit accentColorChanged();
    emit iconPackChanged();
    emit lowPowerModeChanged();
    emit telemetryEnabledChanged();
    emit updateAvailableChanged();
    emit updateVersionChanged();
    emit eqBandsChanged();
    emit subDelayChanged();
    qInfo() << "M3 settings: reset to defaults (stub)";
}

QStringList SettingsStore::accentPalette() const
{
    // 9 swatches per Settings-global.png (VLC orange first, selected).
    return QStringList{
        QStringLiteral("#D37918"), QStringLiteral("#B83A2E"),
        QStringLiteral("#A68A1A"), QStringLiteral("#2E9E4A"),
        QStringLiteral("#1A9EB8"), QStringLiteral("#2E5AB8"),
        QStringLiteral("#7A3EB8"), QStringLiteral("#C2427E"),
        QStringLiteral("#8A8A8A"),
    };
}

QStringList SettingsStore::eqBandNames() const
{
    return QStringList{
        QStringLiteral("Preamp"), QStringLiteral("60 Hz"),
        QStringLiteral("170 Hz"), QStringLiteral("310 Hz"),
        QStringLiteral("600 Hz"), QStringLiteral("1 KHz"),
        QStringLiteral("3 KHz"), QStringLiteral("6 KHz"),
        QStringLiteral("12 KHz"), QStringLiteral("14 KHz"),
        QStringLiteral("16 KHz"),
    };
}

QStringList SettingsStore::languageOptions() const
{
    // M6 i18n: English ships; French/German/Spanish are QTranslator stubs
    // (no .qm bundled yet — see app/i18n/); Pseudo-RTL exercises layout
    // mirroring + bidi without a translation file.
    return QStringList{QStringLiteral("English"), QStringLiteral("French"),
                       QStringLiteral("German"), QStringLiteral("Spanish"),
                       QStringLiteral("Pseudo-RTL (test)")};
}

QStringList SettingsStore::themeOptions() const
{
    return QStringList{QStringLiteral("Dark"), QStringLiteral("Light"),
                       QStringLiteral("System")};
}

QStringList SettingsStore::iconPackOptions() const
{
    // M4 IconTheme: Two-tone ships; Lucide / Phosphor / Material fall back
    // to Two-tone (full 3-pack bundling + attribution follow-up).
    return QStringList{QStringLiteral("Two-tone"), QStringLiteral("Lucide"),
                       QStringLiteral("Phosphor"), QStringLiteral("Material")};
}

QStringList SettingsStore::eqPresetOptions() const
{
    return QStringList{QStringLiteral("None"), QStringLiteral("Flat"),
                       QStringLiteral("Rock"), QStringLiteral("Pop"),
                       QStringLiteral("Jazz"), QStringLiteral("Classical")};
}

QStringList SettingsStore::spatialModeOptions() const
{
    return QStringList{QStringLiteral("Headphone virtualization"),
                       QStringLiteral("Speaker virtualization"),
                       QStringLiteral("Dolby Atmos")};
}

QStringList SettingsStore::logLevelOptions() const
{
    return QStringList{QStringLiteral("Errors only"), QStringLiteral("Warnings"),
                       QStringLiteral("Info"), QStringLiteral("Debug")};
}

double SettingsStore::eqBand(int index) const
{
    if (index < 0 || index >= m_eqBands.size())
        return 0.0;
    return m_eqBands.at(index).toDouble();
}

void SettingsStore::setEqBand(int index, double dB)
{
    if (index < 0 || index >= m_eqBands.size())
        return;
    const double clamped = qBound(-20.0, dB, 20.0);
    if (qFuzzyCompare(m_eqBands.at(index).toDouble() + 1.0, clamped + 1.0))
        return;
    m_eqBands[index] = clamped;
    put(QStringLiteral("m3/audio/eq/band") + QString::number(index), clamped);
    qInfo() << "M3 eq band" << index << "=" << clamped
            << "dB (stub: libvlc_equalizer_set_amp lands in M4)";
    emit eqBandsChanged();
}

// --- Live libVLC mapping stubs (real engine lands in M4) ---
void SettingsStore::applyEqualizer()
{
    qInfo() << "M3 applyEqualizer (stub): enabled=" << m_eqEnabled
            << "preset=" << m_eqPreset << "bands=" << m_eqBands
            << "-> libvlc_audio_equalizer_* in M4";
}

void SettingsStore::applySpuDelay()
{
    qInfo() << "M3 applySpuDelay (stub): delay=" << m_subDelay
            << "s -> libvlc_media_player_set_spu_delay in M4";
}

void SettingsStore::applyVideoAdjust()
{
    qInfo() << "M3 applyVideoAdjust (stub): hue/brightness/contrast via"
            << "libvlc_video_set_adjust_* in M4";
}

void SettingsStore::applyAudioFilters()
{
    qInfo() << "M3 applyAudioFilters (stub): compressor/reverb/delay via"
            << "libvlc_audio_filter in M4";
}

// --- M6 diagnostics + update stubs (Logger owns the file/level state) ---
QString SettingsStore::exportLogBundle(const QString &destPath)
{
    // Keep Logger in sync with the latest toggle/level before exporting.
    Logger::instance().install(m_saveLog, m_logFile, m_logLevel);
    const QString bundle = Logger::instance().exportLogBundle(destPath);
    qInfo() << "M6 diagnostics: exportLogBundle ->" << bundle;
    return bundle;
}

void SettingsStore::checkForUpdates()
{
    if (!m_checkUpdates) {
        qInfo() << "M6 update: skipped (automatic checks OFF; enable in Startup)";
        return;
    }
    // Stub feed: report up-to-date. Real HTTPS feed + signature verify +
    // installer relaunch lands after M6 (see README Packaging notes).
    m_updateAvailable = false;
    m_updateVersion.clear();
    qInfo() << "M6 update: checked (stub feed) — you are up to date";
    emit updateAvailableChanged();
    emit updateVersionChanged();
}

// --- Typed accessors (persist + log + notify) ---
#define M3_STRING_PROP(Class, Name, Key, Member)   \
    QString Class::Name() const { return Member; } \
    void Class::set##Name##Helper() {}

QString SettingsStore::language() const { return m_language; }
void SettingsStore::setLanguage(const QString &v)
{
    if (m_language == v)
        return;
    m_language = v.isEmpty() ? QStringLiteral("English") : v;
    put(QStringLiteral("m3/appearance/language"), m_language);
    qInfo() << "M3 settings: appearance/language =" << m_language;
    emit languageChanged();
}

QString SettingsStore::themeMode() const { return m_themeMode; }
void SettingsStore::setThemeMode(const QString &v)
{
    if (m_themeMode == v)
        return;
    m_themeMode = v.isEmpty() ? QStringLiteral("Dark") : v;
    put(QStringLiteral("m3/appearance/theme"), m_themeMode);
    qInfo() << "M3 settings: appearance/theme =" << m_themeMode;
    emit themeModeChanged();
}

QString SettingsStore::accentColor() const { return m_accentColor; }
void SettingsStore::setAccentColor(const QString &v)
{
    if (m_accentColor == v)
        return;
    m_accentColor = v.isEmpty() ? QStringLiteral("#D37918") : v;
    put(QStringLiteral("m3/appearance/accent"), m_accentColor);
    qInfo() << "M3 settings: appearance/accent =" << m_accentColor;
    emit accentColorChanged();
}

QString SettingsStore::iconPack() const { return m_iconPack; }
void SettingsStore::setIconPack(const QString &v)
{
    if (m_iconPack == v)
        return;
    m_iconPack = v.isEmpty() ? QStringLiteral("Two-tone") : v;
    put(QStringLiteral("m3/appearance/iconPack"), m_iconPack);
    qInfo() << "M4 icontheme: appearance/iconPack =" << m_iconPack
            << "(Two-tone ships; others fallback, see Icon.qml)";
    emit iconPackChanged();
}

bool SettingsStore::showConfirmDialogs() const { return m_showConfirmDialogs; }
void SettingsStore::setShowConfirmDialogs(bool v)
{
    if (m_showConfirmDialogs == v)
        return;
    m_showConfirmDialogs = v;
    put(QStringLiteral("m3/startup/confirmDialogs"), v);
    qInfo() << "M3 settings: startup/confirmDialogs =" << v;
    emit showConfirmDialogsChanged();
}

bool SettingsStore::checkUpdates() const { return m_checkUpdates; }
void SettingsStore::setCheckUpdates(bool v)
{
    if (m_checkUpdates == v)
        return;
    m_checkUpdates = v;
    put(QStringLiteral("m3/startup/checkUpdates"), v);
    qInfo() << "M3 settings: startup/checkUpdates =" << v;
    emit checkUpdatesChanged();
}

bool SettingsStore::developerMode() const { return m_developerMode; }
void SettingsStore::setDeveloperMode(bool v)
{
    if (m_developerMode == v)
        return;
    m_developerMode = v;
    put(QStringLiteral("m3/diagnostics/developerMode"), v);
    qInfo() << "M3 settings: diagnostics/developerMode =" << v;
    emit developerModeChanged();
}

bool SettingsStore::saveLog() const { return m_saveLog; }
void SettingsStore::setSaveLog(bool v)
{
    if (m_saveLog == v)
        return;
    m_saveLog = v;
    put(QStringLiteral("m3/diagnostics/saveLog"), v);
    qInfo() << "M3 settings: diagnostics/saveLog =" << v;
    Logger::instance().setSaveLog(v);
    emit saveLogChanged();
}

QString SettingsStore::logFile() const { return m_logFile; }
void SettingsStore::setLogFile(const QString &v)
{
    if (m_logFile == v)
        return;
    m_logFile = v;
    put(QStringLiteral("m3/diagnostics/logFile"), m_logFile);
    qInfo() << "M3 settings: diagnostics/logFile =" << m_logFile;
    emit logFileChanged();
}

QString SettingsStore::logLevel() const { return m_logLevel; }
void SettingsStore::setLogLevel(const QString &v)
{
    if (m_logLevel == v)
        return;
    m_logLevel = v.isEmpty() ? QStringLiteral("Errors only") : v;
    put(QStringLiteral("m3/diagnostics/logLevel"), m_logLevel);
    qInfo() << "M3 settings: diagnostics/logLevel =" << m_logLevel;
    Logger::instance().setLogLevel(m_logLevel);
    emit logLevelChanged();
}

bool SettingsStore::lowPowerMode() const { return m_lowPowerMode; }
void SettingsStore::setLowPowerMode(bool v)
{
    if (m_lowPowerMode == v)
        return;
    m_lowPowerMode = v;
    put(QStringLiteral("m5/performance/lowPower"), v);
    qInfo() << "M5 settings: performance/lowPower =" << v
            << "(stub: disables Canvas FX + gradients for 60fps)";
    emit lowPowerModeChanged();
}

bool SettingsStore::telemetryEnabled() const { return m_telemetryEnabled; }
void SettingsStore::setTelemetryEnabled(bool v)
{
    if (m_telemetryEnabled == v)
        return;
    m_telemetryEnabled = v;
    put(QStringLiteral("m6/privacy/telemetry"), v);
    // Privacy default OFF: enabling is an explicit opt-in; nothing phones
    // home in M6 (no network client ships — see README follow-ups).
    qInfo() << "M6 privacy: telemetryEnabled =" << v << "(opt-in, no-op stub)";
    emit telemetryEnabledChanged();
}

bool SettingsStore::updateAvailable() const { return m_updateAvailable; }
QString SettingsStore::updateVersion() const { return m_updateVersion; }

bool SettingsStore::eqEnabled() const { return m_eqEnabled; }
void SettingsStore::setEqEnabled(bool v)
{
    if (m_eqEnabled == v)
        return;
    m_eqEnabled = v;
    put(QStringLiteral("m3/audio/eq/enabled"), v);
    qInfo() << "M3 settings: audio/eq/enabled =" << v;
    emit eqEnabledChanged();
}

QString SettingsStore::eqPreset() const { return m_eqPreset; }
void SettingsStore::setEqPreset(const QString &v)
{
    if (m_eqPreset == v)
        return;
    m_eqPreset = v.isEmpty() ? QStringLiteral("None") : v;
    put(QStringLiteral("m3/audio/eq/preset"), m_eqPreset);
    qInfo() << "M3 settings: audio/eq/preset =" << m_eqPreset;
    emit eqPresetChanged();
}

QVariantList SettingsStore::eqBands() const { return m_eqBands; }

bool SettingsStore::twoPass() const { return m_twoPass; }
void SettingsStore::setTwoPass(bool v)
{
    if (m_twoPass == v)
        return;
    m_twoPass = v;
    put(QStringLiteral("m3/audio/twoPass"), v);
    qInfo() << "M3 settings: audio/twoPass =" << v;
    emit twoPassChanged();
}

bool SettingsStore::spatialAudio() const { return m_spatialAudio; }
void SettingsStore::setSpatialAudio(bool v)
{
    if (m_spatialAudio == v)
        return;
    m_spatialAudio = v;
    put(QStringLiteral("m3/audio/spatial"), v);
    qInfo() << "M3 settings: audio/spatial =" << v;
    emit spatialAudioChanged();
}

QString SettingsStore::spatialMode() const { return m_spatialMode; }
void SettingsStore::setSpatialMode(const QString &v)
{
    if (m_spatialMode == v)
        return;
    m_spatialMode = v.isEmpty() ? QStringLiteral("Headphone virtualization") : v;
    put(QStringLiteral("m3/audio/spatialMode"), m_spatialMode);
    qInfo() << "M3 settings: audio/spatialMode =" << m_spatialMode;
    emit spatialModeChanged();
}

bool SettingsStore::stereoWidening() const { return m_stereoWidening; }
void SettingsStore::setStereoWidening(bool v)
{
    if (m_stereoWidening == v)
        return;
    m_stereoWidening = v;
    put(QStringLiteral("m3/audio/stereoWidening"), v);
    qInfo() << "M3 settings: audio/stereoWidening =" << v;
    emit stereoWideningChanged();
}

int SettingsStore::subTrack() const { return m_subTrack; }
void SettingsStore::setSubTrack(int v)
{
    const int clamped = qBound(0, v, 64);
    if (m_subTrack == clamped)
        return;
    m_subTrack = clamped;
    put(QStringLiteral("m3/subtitles/track"), m_subTrack);
    qInfo() << "M3 settings: subtitles/track =" << m_subTrack;
    emit subTrackChanged();
}

QString SettingsStore::subLanguage() const { return m_subLanguage; }
void SettingsStore::setSubLanguage(const QString &v)
{
    if (m_subLanguage == v)
        return;
    m_subLanguage = v.isEmpty() ? QStringLiteral("English") : v;
    put(QStringLiteral("m3/subtitles/language"), m_subLanguage);
    qInfo() << "M3 settings: subtitles/language =" << m_subLanguage;
    emit subLanguageChanged();
}

double SettingsStore::subDelay() const { return m_subDelay; }
void SettingsStore::setSubDelay(double v)
{
    const double clamped = qBound(-10.0, v, 10.0);
    if (qFuzzyCompare(m_subDelay + 1.0, clamped + 1.0))
        return;
    m_subDelay = clamped;
    put(QStringLiteral("m3/subtitles/delay"), m_subDelay);
    qInfo() << "M3 settings: subtitles/delay =" << m_subDelay
            << "(stub: libvlc_media_player_set_spu_delay in M4)";
    emit subDelayChanged();
}

double SettingsStore::subSpeed() const { return m_subSpeed; }
void SettingsStore::setSubSpeed(double v)
{
    if (qFuzzyCompare(m_subSpeed + 1.0, v + 1.0))
        return;
    m_subSpeed = v;
    put(QStringLiteral("m3/subtitles/speed"), m_subSpeed);
    qInfo() << "M3 settings: subtitles/speed =" << m_subSpeed;
    emit subSpeedChanged();
}

double SettingsStore::subDurationFactor() const { return m_subDurationFactor; }
void SettingsStore::setSubDurationFactor(double v)
{
    if (qFuzzyCompare(m_subDurationFactor + 1.0, v + 1.0))
        return;
    m_subDurationFactor = v;
    put(QStringLiteral("m3/subtitles/durationFactor"), m_subDurationFactor);
    qInfo() << "M3 settings: subtitles/durationFactor =" << m_subDurationFactor;
    emit subDurationFactorChanged();
}

bool SettingsStore::embeddedSubFormat() const { return m_embeddedSubFormat; }
void SettingsStore::setEmbeddedSubFormat(bool v)
{
    if (m_embeddedSubFormat == v)
        return;
    m_embeddedSubFormat = v;
    put(QStringLiteral("m3/subtitles/embeddedFormat"), v);
    qInfo() << "M3 settings: subtitles/embeddedFormat =" << v;
    emit embeddedSubFormatChanged();
}

QString SettingsStore::subFont() const { return m_subFont; }
void SettingsStore::setSubFont(const QString &v)
{
    if (m_subFont == v)
        return;
    m_subFont = v.isEmpty() ? QStringLiteral("Inter") : v;
    put(QStringLiteral("m3/subtitles/font"), m_subFont);
    qInfo() << "M3 settings: subtitles/font =" << m_subFont;
    emit subFontChanged();
}

QString SettingsStore::textColor() const { return m_textColor; }
void SettingsStore::setTextColor(const QString &v)
{
    if (m_textColor == v)
        return;
    m_textColor = v.isEmpty() ? QStringLiteral("#B8B8B8") : v;
    put(QStringLiteral("m3/subtitles/textColor"), m_textColor);
    qInfo() << "M3 settings: subtitles/textColor =" << m_textColor;
    emit textColorChanged();
}

QString SettingsStore::outlineColor() const { return m_outlineColor; }
void SettingsStore::setOutlineColor(const QString &v)
{
    if (m_outlineColor == v)
        return;
    m_outlineColor = v.isEmpty() ? QStringLiteral("#0C0C0C") : v;
    put(QStringLiteral("m3/subtitles/outlineColor"), m_outlineColor);
    qInfo() << "M3 settings: subtitles/outlineColor =" << m_outlineColor;
    emit outlineColorChanged();
}

int SettingsStore::schemaVersion() const { return m_schemaVersion; }

void SettingsStore::loadAll()
{
    QSettings s(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"));
    m_language = s.value(QStringLiteral("m3/appearance/language"), m_language).toString();
    m_themeMode = s.value(QStringLiteral("m3/appearance/theme"), m_themeMode).toString();
    m_accentColor = s.value(QStringLiteral("m3/appearance/accent"), m_accentColor).toString();
    m_iconPack = s.value(QStringLiteral("m3/appearance/iconPack"), m_iconPack).toString();
    m_showConfirmDialogs = s.value(QStringLiteral("m3/startup/confirmDialogs"), m_showConfirmDialogs).toBool();
    m_checkUpdates = s.value(QStringLiteral("m3/startup/checkUpdates"), m_checkUpdates).toBool();
    m_developerMode = s.value(QStringLiteral("m3/diagnostics/developerMode"), m_developerMode).toBool();
    m_saveLog = s.value(QStringLiteral("m3/diagnostics/saveLog"), m_saveLog).toBool();
    m_logFile = s.value(QStringLiteral("m3/diagnostics/logFile"), m_logFile).toString();
    m_logLevel = s.value(QStringLiteral("m3/diagnostics/logLevel"), m_logLevel).toString();
    m_eqEnabled = s.value(QStringLiteral("m3/audio/eq/enabled"), m_eqEnabled).toBool();
    m_eqPreset = s.value(QStringLiteral("m3/audio/eq/preset"), m_eqPreset).toString();
    for (int i = 0; i < m_eqBands.size(); ++i)
        m_eqBands[i] = s.value(QStringLiteral("m3/audio/eq/band") + QString::number(i),
                               m_eqBands.at(i)).toDouble();
    m_twoPass = s.value(QStringLiteral("m3/audio/twoPass"), m_twoPass).toBool();
    m_spatialAudio = s.value(QStringLiteral("m3/audio/spatial"), m_spatialAudio).toBool();
    m_spatialMode = s.value(QStringLiteral("m3/audio/spatialMode"), m_spatialMode).toString();
    m_stereoWidening = s.value(QStringLiteral("m3/audio/stereoWidening"), m_stereoWidening).toBool();
    m_subTrack = s.value(QStringLiteral("m3/subtitles/track"), m_subTrack).toInt();
    m_subLanguage = s.value(QStringLiteral("m3/subtitles/language"), m_subLanguage).toString();
    m_subDelay = s.value(QStringLiteral("m3/subtitles/delay"), m_subDelay).toDouble();
    m_subSpeed = s.value(QStringLiteral("m3/subtitles/speed"), m_subSpeed).toDouble();
    m_subDurationFactor = s.value(QStringLiteral("m3/subtitles/durationFactor"), m_subDurationFactor).toDouble();
    m_embeddedSubFormat = s.value(QStringLiteral("m3/subtitles/embeddedFormat"), m_embeddedSubFormat).toBool();
    m_subFont = s.value(QStringLiteral("m3/subtitles/font"), m_subFont).toString();
    m_textColor = s.value(QStringLiteral("m3/subtitles/textColor"), m_textColor).toString();
    m_outlineColor = s.value(QStringLiteral("m3/subtitles/outlineColor"), m_outlineColor).toString();
    m_lowPowerMode = s.value(QStringLiteral("m5/performance/lowPower"), m_lowPowerMode).toBool();
    m_telemetryEnabled = s.value(QStringLiteral("m6/privacy/telemetry"), m_telemetryEnabled).toBool();
}

void SettingsStore::migrateIfNeeded()
{
    QSettings s(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"));
    const int stored = s.value(QStringLiteral("m3/schemaVersion"), 0).toInt();
    if (stored >= kSchemaVersion) {
        m_schemaVersion = stored;
        return;
    }
    // M4 adds m3/appearance/iconPack (default Two-tone); existing M3 keys
    // carry forward untouched. Future libVLC-backed EQ/spu keys branch here.
    if (stored == 3) {
        qInfo() << "M4 SettingsStore: migrating schema 3 -> 4"
                << "(add appearance/iconPack=Two-tone, keep M3 keys)";
        if (!s.contains(QStringLiteral("m3/appearance/iconPack")))
            s.setValue(QStringLiteral("m3/appearance/iconPack"), QStringLiteral("Two-tone"));
    }
    // M5 adds m5/performance/lowPower (default OFF); M3/M4 keys untouched.
    if (stored == 4) {
        qInfo() << "M5 SettingsStore: migrating schema 4 -> 5"
                << "(add performance/lowPower=false, keep M3/M4 keys)";
        if (!s.contains(QStringLiteral("m5/performance/lowPower")))
            s.setValue(QStringLiteral("m5/performance/lowPower"), false);
    } else if (stored == 5) {
        qInfo() << "M6 SettingsStore: migrating schema 5 -> 6"
                << "(add privacy/telemetry=false, keep M3/M4/M5 keys)";
        if (!s.contains(QStringLiteral("m6/privacy/telemetry")))
            s.setValue(QStringLiteral("m6/privacy/telemetry"), false);
    } else if (stored != 3) {
        qInfo() << "M3 SettingsStore: migrating schema" << stored << "->" << kSchemaVersion
                << "(stub: namespaced keys, no legacy import)";
    }
    s.setValue(QStringLiteral("m3/schemaVersion"), kSchemaVersion);
    m_schemaVersion = kSchemaVersion;
}

void SettingsStore::put(const QString &key, const QVariant &val)
{
    QSettings s(QStringLiteral("VLC"), QStringLiteral("VLC Redesign"));
    s.setValue(key, val);
}
