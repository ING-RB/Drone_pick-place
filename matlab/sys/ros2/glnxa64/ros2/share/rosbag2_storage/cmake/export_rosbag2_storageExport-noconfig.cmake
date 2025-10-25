#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rosbag2_storage::rosbag2_storage" for configuration ""
set_property(TARGET rosbag2_storage::rosbag2_storage APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rosbag2_storage::rosbag2_storage PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librosbag2_storage.so"
  IMPORTED_SONAME_NOCONFIG "librosbag2_storage.so"
  )

list(APPEND _cmake_import_check_targets rosbag2_storage::rosbag2_storage )
list(APPEND _cmake_import_check_files_for_rosbag2_storage::rosbag2_storage "${_IMPORT_PREFIX}/lib/librosbag2_storage.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
