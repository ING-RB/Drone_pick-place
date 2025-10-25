#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "CycloneDDS::idlc" for configuration "RelWithDebInfo"
set_property(TARGET CycloneDDS::idlc APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(CycloneDDS::idlc PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/bin/idlc"
  )

list(APPEND _cmake_import_check_targets CycloneDDS::idlc )
list(APPEND _cmake_import_check_files_for_CycloneDDS::idlc "${_IMPORT_PREFIX}/bin/idlc" )

# Import target "CycloneDDS::idl" for configuration "RelWithDebInfo"
set_property(TARGET CycloneDDS::idl APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(CycloneDDS::idl PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libcycloneddsidl.so.0.10.5"
  IMPORTED_SONAME_RELWITHDEBINFO "libcycloneddsidl.so.0"
  )

list(APPEND _cmake_import_check_targets CycloneDDS::idl )
list(APPEND _cmake_import_check_files_for_CycloneDDS::idl "${_IMPORT_PREFIX}/lib/libcycloneddsidl.so.0.10.5" )

# Import target "CycloneDDS::ddsc" for configuration "RelWithDebInfo"
set_property(TARGET CycloneDDS::ddsc APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(CycloneDDS::ddsc PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libddsc.so.0.10.5"
  IMPORTED_SONAME_RELWITHDEBINFO "libddsc.so.0"
  )

list(APPEND _cmake_import_check_targets CycloneDDS::ddsc )
list(APPEND _cmake_import_check_files_for_CycloneDDS::ddsc "${_IMPORT_PREFIX}/lib/libddsc.so.0.10.5" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
