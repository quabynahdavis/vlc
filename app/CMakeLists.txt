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
    Ds/Theme.qml
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
