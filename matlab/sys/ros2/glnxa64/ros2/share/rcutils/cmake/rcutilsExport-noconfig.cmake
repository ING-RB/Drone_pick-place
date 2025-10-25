#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rcutils::rcutils" for configuration ""
set_property(TARGET rcutils::rcutils APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rcutils::rcutils PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librcutils.so"
  IMPORTED_SONAME_NOCONFIG "librcutils.so"
  )

list(APPEND _cmake_import_check_targets rcutils::rcutils )
list(APPEND _cmake_import_check_files_for_rcutils::rcutils "${_IMPORT_PREFIX}/lib/librcutils.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
