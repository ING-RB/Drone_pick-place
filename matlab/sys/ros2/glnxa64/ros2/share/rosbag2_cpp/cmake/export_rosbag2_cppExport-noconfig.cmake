#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rosbag2_cpp::rosbag2_cpp" for configuration ""
set_property(TARGET rosbag2_cpp::rosbag2_cpp APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rosbag2_cpp::rosbag2_cpp PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_NOCONFIG "ament_index_cpp::ament_index_cpp;rosidl_typesupport_cpp::rosidl_typesupport_cpp"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librosbag2_cpp.so"
  IMPORTED_SONAME_NOCONFIG "librosbag2_cpp.so"
  )

list(APPEND _cmake_import_check_targets rosbag2_cpp::rosbag2_cpp )
list(APPEND _cmake_import_check_files_for_rosbag2_cpp::rosbag2_cpp "${_IMPORT_PREFIX}/lib/librosbag2_cpp.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
