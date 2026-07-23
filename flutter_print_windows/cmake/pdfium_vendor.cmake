# Offline PDFium from windows/vendor/ (see vendor/README.md + scripts/download_vendor.ps1).

set(FLUTTER_PRINT_PDFIUM_VENDOR_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vendor")

function(_flutter_print_check_pdfium_tree dir result_var)
  if(EXISTS "${dir}/include/fpdfview.h"
      AND EXISTS "${dir}/lib/pdfium.dll.lib"
      AND EXISTS "${dir}/bin/pdfium.dll")
    set(${result_var} TRUE PARENT_SCOPE)
  else()
    set(${result_var} FALSE PARENT_SCOPE)
  endif()
endfunction()

function(_flutter_print_verify_pdfium_archive archive expected_sha256)
  if(NOT EXISTS "${archive}")
    message(FATAL_ERROR
      "PDFium vendor archive not found: ${archive}\n"
      "Run: flutter_print_windows/scripts/download_vendor.ps1"
    )
  endif()

  file(SHA256 "${archive}" actual_sha256)
  string(TOLOWER "${actual_sha256}" actual_sha256)
  string(TOLOWER "${expected_sha256}" expected_sha256)

  if(NOT actual_sha256 STREQUAL expected_sha256)
    message(FATAL_ERROR
      "PDFium archive integrity check failed: ${archive}\n"
      "Expected SHA256 ${expected_sha256}, got ${actual_sha256}."
    )
  endif()
endfunction()

function(flutter_print_resolve_pdfium out_var)
  if("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-x64")
    set(_arch_dir "x86_64")
    set(_archive_name "pdfium-win-x64.tgz")
    set(_sha256 "b904e3898f952984fb744e0c8eb36512b5ee527124796108ed419a5b4da3c6d9")
  elseif("${FLUTTER_TARGET_PLATFORM}" STREQUAL "windows-arm64")
    set(_arch_dir "aarch64")
    set(_archive_name "pdfium-win-arm64.tgz")
    set(_sha256 "12238aba08002328fb8adc7225921771427eee1cf463cca3694beecf41e4d7c5")
  else()
    message(FATAL_ERROR
      "flutter_print_windows: unsupported FLUTTER_TARGET_PLATFORM "
      "'${FLUTTER_TARGET_PLATFORM}' (expected windows-x64 or windows-arm64)."
    )
  endif()

  set(_vendor_arch "${FLUTTER_PRINT_PDFIUM_VENDOR_ROOT}/${_arch_dir}")
  set(_vendor_tree "${_vendor_arch}/pdfium")
  set(_vendor_archive "${_vendor_arch}/${_archive_name}")
  set(_build_tree "${CMAKE_BINARY_DIR}/pdfium")

  _flutter_print_check_pdfium_tree("${_vendor_tree}" _vendor_tree_ok)
  if(_vendor_tree_ok)
    message(STATUS "Using vendored PDFium tree: ${_vendor_tree}")
    set(${out_var} "${_vendor_tree}" PARENT_SCOPE)
    return()
  endif()

  _flutter_print_check_pdfium_tree("${_build_tree}" _build_tree_ok)
  if(_build_tree_ok)
    message(STATUS "Using extracted PDFium tree: ${_build_tree}")
    set(${out_var} "${_build_tree}" PARENT_SCOPE)
    return()
  endif()

  _flutter_print_verify_pdfium_archive("${_vendor_archive}" "${_sha256}")

  message(STATUS "Extracting ${_archive_name} into ${_build_tree}")
  file(MAKE_DIRECTORY "${_build_tree}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xzf "${_vendor_archive}"
    WORKING_DIRECTORY "${_build_tree}"
    RESULT_VARIABLE _tar_result
  )
  if(NOT _tar_result EQUAL 0)
    message(FATAL_ERROR "Failed to extract PDFium archive: ${_vendor_archive}")
  endif()

  _flutter_print_check_pdfium_tree("${_build_tree}" _build_tree_ok)
  if(NOT _build_tree_ok)
    message(FATAL_ERROR
      "PDFium layout invalid after extract: ${_build_tree}\n"
      "Expected include/, lib/pdfium.dll.lib, bin/pdfium.dll"
    )
  endif()

  set(${out_var} "${_build_tree}" PARENT_SCOPE)
endfunction()
