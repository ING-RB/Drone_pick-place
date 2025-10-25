#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rosbag2_compression::rosbag2_compression" for configuration ""
set_property(TARGET rosbag2_compression::rosbag2_compression APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rosbag2_compression::rosbag2_compression PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librosbag2_compression.so"
  IMPORTED_SONAME_NOCONFIG "librosbag2_compression.so"
  )

list(APPEND _cmake_import_check_targets rosbag2_compression::rosbag2_compression )
list(APPEND _cmake_import_check_files_for_rosbag2_compression::rosbag2_compression "${_IMPORT_PREFIX}/lib/librosbag2_compression.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
