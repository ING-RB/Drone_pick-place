#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "class_loader::class_loader" for configuration ""
set_property(TARGET class_loader::class_loader APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(class_loader::class_loader PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libclass_loader.so"
  IMPORTED_SONAME_NOCONFIG "libclass_loader.so"
  )

list(APPEND _cmake_import_check_targets class_loader::class_loader )
list(APPEND _cmake_import_check_files_for_class_loader::class_loader "${_IMPORT_PREFIX}/lib/libclass_loader.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
