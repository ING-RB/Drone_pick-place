# Copyright (C) 2018 The MathWorks, Inc.
# MathWorks-specific modifications have been made to the original source. 

if(DEFINED CCD_SINGLE OR DEFINED CCD_DOUBLE)
  # make sure only DOUBLE or SINGLE is set; default to SINGLE
  if(CCD_SINGLE)
    set(CCD_DOUBLE OFF)
  else()
    set(CCD_SINGLE ON)
  endif()
  if(CCD_DOUBLE)
    set(CCD_SINGLE OFF)
  endif()
elseif(ENABLE_DOUBLE_PRECISION)
    set(CCD_DOUBLE ON)
    set(CCD_SINGLE OFF)
else()
    set(CCD_DOUBLE OFF)
    set(CCD_SINGLE ON)
endif()

configure_file(ccd/ccd_config.h.cmake.in ccd/ccd_config.h)

set(CCD_INCLUDES
  ccd/ccd_ccd.h
  ccd/ccd_compiler.h
  ccd/ccd_ccd_export.h
  ccd/ccd_quat.h
  ccd/ccd_vec3.h
  ccd/ccd_list.h
  ccd/ccd_polytope.h
  ccd/ccd_support.h
  ccd/ccd_simplex.h
  "${CMAKE_CURRENT_BINARY_DIR}/ccd/ccd_config.h")

set(CCD_SOURCES
  ccd_alloc.h
  ccd_ccd.c
  ccd_dbg.h
  ccd_mpr.c
  ccd_polytope.c
  ccd_vec3.c)

add_library(ccd ${CCD_INCLUDES} ${CCD_SOURCES})

set_target_properties(ccd PROPERTIES
  PUBLIC_HEADER "${CCD_INCLUDES}"
  SOVERSION ${CCD_SOVERSION}
  VERSION ${CCD_VERSION})
target_include_directories(ccd PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)

if(NOT WIN32)
  find_library(LIBM_LIBRARY NAMES m)
  if(NOT LIBM_LIBRARY)
    message(FATAL_ERROR "Could NOT find required library LibM")
  endif()
  message("Standard Math Library: " ${LIBM_LIBRARY})
  target_link_libraries(ccd "${LIBM_LIBRARY}")
  if(BUILD_SHARED_LIBS)
    set(CCD_PKGCONFIG_EXTRA_LIBS -lm PARENT_SCOPE)
  endif()
endif()

export(TARGETS ccd FILE "${CMAKE_BINARY_DIR}/ccd-targets.cmake")

install(TARGETS ccd
  EXPORT ccd-targets
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/ccd"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(EXPORT ccd-targets DESTINATION "${CMAKE_INSTALL_LIBDIR}/ccd")

macro (check_compiler_visibility)
  include (CheckCXXCompilerFlag)
  check_cxx_compiler_flag(-fvisibility=hidden COMPILER_SUPPORTS_VISIBILITY)
endmacro()

if(UNIX)
  check_compiler_visibility()
  if (COMPILER_SUPPORTS_VISIBILITY)
    set_target_properties(ccd
         PROPERTIES COMPILE_FLAGS "-fvisibility=hidden")
  endif()
endif()


add_subdirectory(testsuites)

