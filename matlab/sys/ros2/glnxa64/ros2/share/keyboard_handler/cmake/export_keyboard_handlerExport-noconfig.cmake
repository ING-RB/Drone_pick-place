#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "keyboard_handler::keyboard_handler" for configuration ""
set_property(TARGET keyboard_handler::keyboard_handler APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(keyboard_handler::keyboard_handler PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libkeyboard_handler.so"
  IMPORTED_SONAME_NOCONFIG "libkeyboard_handler.so"
  )

list(APPEND _cmake_import_check_targets keyboard_handler::keyboard_handler )
list(APPEND _cmake_import_check_files_for_keyboard_handler::keyboard_handler "${_IMPORT_PREFIX}/lib/libkeyboard_handler.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
