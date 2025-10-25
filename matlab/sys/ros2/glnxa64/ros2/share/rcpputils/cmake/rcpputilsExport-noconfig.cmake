#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rcpputils::rcpputils" for configuration ""
set_property(TARGET rcpputils::rcpputils APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rcpputils::rcpputils PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librcpputils.so"
  IMPORTED_SONAME_NOCONFIG "librcpputils.so"
  )

list(APPEND _cmake_import_check_targets rcpputils::rcpputils )
list(APPEND _cmake_import_check_files_for_rcpputils::rcpputils "${_IMPORT_PREFIX}/lib/librcpputils.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
