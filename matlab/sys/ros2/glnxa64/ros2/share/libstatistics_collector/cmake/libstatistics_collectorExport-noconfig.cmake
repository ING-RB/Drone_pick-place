#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "libstatistics_collector::libstatistics_collector" for configuration ""
set_property(TARGET libstatistics_collector::libstatistics_collector APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(libstatistics_collector::libstatistics_collector PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/liblibstatistics_collector.so"
  IMPORTED_SONAME_NOCONFIG "liblibstatistics_collector.so"
  )

list(APPEND _cmake_import_check_targets libstatistics_collector::libstatistics_collector )
list(APPEND _cmake_import_check_files_for_libstatistics_collector::libstatistics_collector "${_IMPORT_PREFIX}/lib/liblibstatistics_collector.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
