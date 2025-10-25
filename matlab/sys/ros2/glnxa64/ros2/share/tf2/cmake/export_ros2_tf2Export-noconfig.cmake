#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "tf2::ros2_tf2" for configuration ""
set_property(TARGET tf2::ros2_tf2 APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(tf2::ros2_tf2 PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_NOCONFIG "builtin_interfaces::builtin_interfaces__rosidl_generator_c;builtin_interfaces::builtin_interfaces__rosidl_typesupport_fastrtps_c;builtin_interfaces::builtin_interfaces__rosidl_typesupport_introspection_c;builtin_interfaces::builtin_interfaces__rosidl_typesupport_c;builtin_interfaces::builtin_interfaces__rosidl_typesupport_fastrtps_cpp;builtin_interfaces::builtin_interfaces__rosidl_typesupport_introspection_cpp;builtin_interfaces::builtin_interfaces__rosidl_typesupport_cpp;rcutils::rcutils"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libros2_tf2.so"
  IMPORTED_SONAME_NOCONFIG "libros2_tf2.so"
  )

list(APPEND _cmake_import_check_targets tf2::ros2_tf2 )
list(APPEND _cmake_import_check_files_for_tf2::ros2_tf2 "${_IMPORT_PREFIX}/lib/libros2_tf2.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
