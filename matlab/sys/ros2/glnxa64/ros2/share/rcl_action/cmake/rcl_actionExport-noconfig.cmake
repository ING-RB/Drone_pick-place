#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rcl_action::rcl_action" for configuration ""
set_property(TARGET rcl_action::rcl_action APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rcl_action::rcl_action PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_NOCONFIG "rcutils::rcutils"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librcl_action.so"
  IMPORTED_SONAME_NOCONFIG "librcl_action.so"
  )

list(APPEND _cmake_import_check_targets rcl_action::rcl_action )
list(APPEND _cmake_import_check_files_for_rcl_action::rcl_action "${_IMPORT_PREFIX}/lib/librcl_action.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
