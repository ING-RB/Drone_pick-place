#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "rclcpp::rclcpp" for configuration ""
set_property(TARGET rclcpp::rclcpp APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(rclcpp::rclcpp PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_NOCONFIG "ament_index_cpp::ament_index_cpp;rcl_logging_interface::rcl_logging_interface"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/librclcpp.so"
  IMPORTED_SONAME_NOCONFIG "librclcpp.so"
  )

list(APPEND _cmake_import_check_targets rclcpp::rclcpp )
list(APPEND _cmake_import_check_files_for_rclcpp::rclcpp "${_IMPORT_PREFIX}/lib/librclcpp.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
