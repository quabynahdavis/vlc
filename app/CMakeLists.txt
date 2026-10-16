cmake_minimum_required(VERSION 3.21)
project(VlcRedesignM0 VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Qt 6.6+ modules required for M0 hello-video.
find_package(Qt6 6.6 REQUIRED COMPONENTS Quick Multimedia Sql)
qt_standard_project_setup(REQUIRES 6.6)

# ------------------------------------------------------------------
# libVLC dependency.
# Linux: pkg-config libvlc (apt: libvlc-dev / vlc).
# Windows/macOS: allow -DVLC_SDK_PATH=<dir> or env VLC_SDK_PATH
# pointing at a VLC SDK / VLC.app bundle containing include/vlc
# and lib/libvlc.
# ------------------------------------------------------------------
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
  pkg_check_modules(LIBVLC IMPORTED_TARGET libvlc)
endif()

if(NOT LIBVLC_FOUND)
  message(STATUS "pkg-config libvlc not found, trying VLC_SDK_PATH fallback")
  find_path(LIBVLC_INCLUDE_DIR
    NAMES vlc/vlc.h
    HINTS
      $ENV{VLC_SDK_PATH}/include
      ${VLC_SDK_PATH}/include
      /Applications/VLC.app/Contents/MacOS/include
  )
  find_library(LIBVLC_LIBRARY
    NAMES vlc libvlc
    HINTS
      $ENV{VLC_SDK_PATH}/lib
      ${VLC_SDK_PATH}/lib
      /Applications/VLC.app/Contents/MacOS/lib
  )
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LIBVLC DEFAULT_MSG LIBVLC_LIBRARY LIBVLC_INCLUDE_DIR)
  if(LIBVLC_FOUND)
    set(LIBVLC_INCLUDE_DIRS ${LIBVLC_INCLUDE_DIR})
    set(LIBVLC_LIBRARIES ${LIBVLC_LIBRARY})
  endif()
endif()

if(NOT LIBVLC_FOUND)
  message(FATAL_ERROR
    "libVLC not found. Install libVLC dev files:\n"
    "  Linux (Debian/Ubuntu/Fedora): libvlc-dev / vlc-devel\n"
    "  Windows: download VLC SDK (see app/README.md) and pass -DVLC_SDK_PATH=<dir>\n"
    "  macOS: install VLC.app + headers (see app/README.md) or brew, pass -DVLC_SDK_PATH=<dir>")
endif()

qt_add_executable(vlc-redesign-m0
  main.cpp
  libraryservice.h
  libraryservice.cpp
  settingsstore.h
  settingsstore.cpp
  logger.h
  logger.cpp
)

# Theme.qml is a QML singleton (import "Ds" as Ds -> Ds.Theme).
set_source_files_properties(Ds/Theme.qml
  PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(vlc-redesign-m0
  URI VlcM0
  VERSION 1.0
  QML_FILES
    Main.qml
    TitleBar.qml
    Icon.qml
    IconRail.qml
    PlaylistDrawer.qml
    TransportBar.qml
    MenuRow.qml
    PlayerContextMenu.qml
    LibraryView.qml
    ThumbnailCard.qml
    ThumbnailWorker.qml
    CreatePlaylistDialog.qml
    SettingToggle.qml
    SliderRow.qml
    CollapsiblePanel.qml
    EqualizerBank.qml
    AudioSettingsPage.qml
    GlobalSettingsDialog.qml
    EffectsDock.qml
    SubtitlesPanel.qml
    ToastHost.qml
    ErrorDialog.qml
    NetworkOpenDialog.qml
    Ds/Theme.qml
  RESOURCES
    icons/two-tone/prev.svg
    icons/two-tone/play.svg
    icons/two-tone/pause.svg
    icons/two-tone/next.svg
    icons/two-tone/volume.svg
    icons/two-tone/eq.svg
    icons/two-tone/subs.svg
    icons/two-tone/settings.svg
    icons/two-tone/queue.svg
    icons/two-tone/home.svg
    icons/two-tone/files.svg
    icons/two-tone/music.svg
    icons/two-tone/radio.svg
    icons/two-tone/playlist.svg
    icons/two-tone/history.svg
    icons/two-tone/add.svg
)

target_link_libraries(vlc-redesign-m0 PRIVATE
  Qt6::Quick
  Qt6::Multimedia
  Qt6::Sql
)

# Link libVLC: prefer PkgConfig imported target, else manual vars.
if(TARGET PkgConfig::LIBVLC)
  target_link_libraries(vlc-redesign-m0 PRIVATE PkgConfig::LIBVLC)
else()
  target_include_directories(vlc-redesign-m0 PRIVATE ${LIBVLC_INCLUDE_DIRS})
  target_link_libraries(vlc-redesign-m0 PRIVATE ${LIBVLC_LIBRARIES})
endif()

install(TARGETS vlc-redesign-m0
  RUNTIME DESTINATION bin
  BUNDLE DESTINATION .
)
# M6: ship the README + i18n stubs alongside the binary so log-bundle,
# locale, and packaging notes travel with the install tree.
install(FILES README.md DESTINATION share/doc/vlc-redesign-m0)
install(DIRECTORY i18n/ DESTINATION share/vlc-redesign-m0/i18n
  FILES_MATCHING PATTERN "*.ts" PATTERN "*.md")

# ------------------------------------------------------------------
# M6 packaging (CPack stub). Generators per-OS (see README):
#   Linux   AppImage via linuxdeploy (+ plugin-qt) — NOT cpack-generated;
#           `cmake --build ... --target package` here emits TGZ/DEB as a CI
#           smoke artifact, the AppImage recipe lives in README.
#   Windows WiX MSI via windeployqt + heat harvest (README recipe).
#   macOS   DMG via macdeployqt + create-dmg (README recipe).
# Follow-ups: sign/notarize, feed signing for auto-update, .qm bundling via
# qt_add_translations (app/i18n/*.ts -> :/i18n), VLC plugins payload.
# ------------------------------------------------------------------
set(CPACK_PACKAGE_NAME "vlc-redesign-m0")
set(CPACK_PACKAGE_VENDOR "VLC")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "VLC desktop shell redesign (Qt6 QML prototype)")
set(CPACK_PACKAGE_CONTACT "vlc@example.invalid")
set(CPACK_GENERATOR "TGZ")
if(WIN32)
  set(CPACK_GENERATOR "WIX;ZIP")
elseif(APPLE)
  set(CPACK_GENERATOR "DragNDrop;TGZ")
else()
  set(CPACK_GENERATOR "TGZ;DEB")
endif()
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libvlc5 (>= 3.0)")
include(CPack)
