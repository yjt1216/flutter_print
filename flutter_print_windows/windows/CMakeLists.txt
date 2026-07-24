cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "flutter_print_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "flutter_print_windows_plugin")

# ---------------------------------------------------------------------------
# PDFium — vendored under windows/vendor/ (see vendor/README.md)
# ---------------------------------------------------------------------------
include("${CMAKE_CURRENT_SOURCE_DIR}/../cmake/pdfium_vendor.cmake")
flutter_print_resolve_pdfium(PDFIUM_ROOT)

# ---------------------------------------------------------------------------
# Plugin sources
# ---------------------------------------------------------------------------
list(APPEND PLUGIN_SOURCES
  "flutter_print_plugin.cpp"
  "flutter_print_plugin.h"
  "flutter_print_utils.cpp"
  "flutter_print_utils.h"
  "printer_setup.cpp"
  "printer_setup.h"
  "document_renderer.cpp"
  "document_renderer.h"
  "print_jobs.cpp"
  "print_jobs.h"
  "messages.cpp"
  "messages.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/flutter_print_windows/flutter_print_plugin_c_api.h"
  "flutter_print_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${PDFIUM_ROOT}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  gdiplus
  "${PDFIUM_ROOT}/lib/pdfium.dll.lib"
)

# pdfium.dll must ship alongside the plugin.
set(flutter_print_windows_bundled_libraries
  "${PDFIUM_ROOT}/bin/pdfium.dll"
  PARENT_SCOPE
)
