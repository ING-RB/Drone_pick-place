#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rcl_logging_interface::rcl_logging_interface" for configuration ""
set_property(TARGET rcl_logging_interface::rcl_logging_interface APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rcl_logging_interface::rcl_logging_interface PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librcl_logging_interface.so"
  IMPORTED_SONAME_NOCONFIG "librcl_logging_interface.so"
  )

list(APPEND _cmake_import_check_targets rcl_logging_interface::rcl_logging_interface )
list(APPEND _cmake_import_check_files_for_rcl_logging_interface::rcl_logging_interface "${_IMPORT_PREFIX}/lib/librcl_logging_interface.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
