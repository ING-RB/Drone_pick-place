#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rcl_yaml_param_parser::rcl_yaml_param_parser" for configuration ""
set_property(TARGET rcl_yaml_param_parser::rcl_yaml_param_parser APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rcl_yaml_param_parser::rcl_yaml_param_parser PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_NOCONFIG "rmw::rmw;yaml"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librcl_yaml_param_parser.so"
  IMPORTED_SONAME_NOCONFIG "librcl_yaml_param_parser.so"
  )

list(APPEND _cmake_import_check_targets rcl_yaml_param_parser::rcl_yaml_param_parser )
list(APPEND _cmake_import_check_files_for_rcl_yaml_param_parser::rcl_yaml_param_parser "${_IMPORT_PREFIX}/lib/librcl_yaml_param_parser.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
