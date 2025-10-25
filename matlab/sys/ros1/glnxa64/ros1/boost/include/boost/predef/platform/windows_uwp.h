#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(__GNUC__)
#    pragma GCC system_header
#  elif defined(_MSC_VER)
     /* The matching "pop" is in header_suffix.h */
#    pragma warning(push, 1)
       /*
        * These suppressions are only here because of the apparent compiler bug:
        * http://komodo.mathworks.com/main/gecko?Action=view&Record=g782945
        *
        * If the bug didn't exist, these warnings would be suppressed solely by
        * the warning(push) above.  The state of the warnings prior to the
        * warning(push) above will be restored by the warning(pop) in the suffix
        * header.
        *
        * Other suppressions may need to be added as more Boost headers are used
        * and other bogus warnings are uncovered.
        */
#      pragma warning(disable: 4003)
#      pragma warning(disable: 4141)
#      pragma warning(disable: 4244)
#      pragma warning(disable: 4702)
#      pragma warning(disable: 4714)
       /* End g782945 workarounds. */
#  endif
#endif

#if !defined(MW_DISABLE_BOOST_DEFAULT_VISIBILITY)
#  if defined(__GNUC__)
#    if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
       /* The matching "pop" is in header_suffix.h */
#      pragma GCC visibility push (default)
#    endif
#  endif
#endif

/*
Copyright James E. King III, 2017
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#ifndef BOOST_PREDEF_PLAT_WINDOWS_UWP_H
#define BOOST_PREDEF_PLAT_WINDOWS_UWP_H

#include <boost/predef/make.h>
#include <boost/predef/os/windows.h>
#include <boost/predef/version_number.h>

/* tag::reference[]
= `BOOST_PLAT_WINDOWS_UWP`

http://docs.microsoft.com/windows/uwp/[Universal Windows Platform]
is available if the current development environment is capable of targeting 
UWP development.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__MINGW64_VERSION_MAJOR+` from `+_mingw.h+` | `>= 3`
| `VER_PRODUCTBUILD` from `ntverp.h` | `>= 9200`
|===
*/ // end::reference[]

#define BOOST_PLAT_WINDOWS_UWP BOOST_VERSION_NUMBER_NOT_AVAILABLE
#define BOOST_PLAT_WINDOWS_SDK_VERSION BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if BOOST_OS_WINDOWS
//  MinGW (32-bit), WinCE, and wineg++ don't have a ntverp.h header
#if !defined(__MINGW32__) && !defined(_WIN32_WCE) && !defined(__WINE__)
#   include <ntverp.h>
#   undef BOOST_PLAT_WINDOWS_SDK_VERSION
#   define BOOST_PLAT_WINDOWS_SDK_VERSION BOOST_VERSION_NUMBER(0, 0, VER_PRODUCTBUILD)
#endif

// 9200 is Windows SDK 8.0 from ntverp.h which introduced family support
#if ((BOOST_PLAT_WINDOWS_SDK_VERSION >= BOOST_VERSION_NUMBER(0, 0, 9200)) || \
     (defined(__MINGW64__) && __MINGW64_VERSION_MAJOR >= 3))
#   undef BOOST_PLAT_WINDOWS_UWP
#   define BOOST_PLAT_WINDOWS_UWP BOOST_VERSION_NUMBER_AVAILABLE
#endif
#endif

#if BOOST_PLAT_WINDOWS_UWP
#   define BOOST_PLAT_WINDOWS_UWP_AVAILABLE
#   include <boost/predef/detail/platform_detected.h>
#   include <winapifamily.h>    // Windows SDK
#endif

#define BOOST_PLAT_WINDOWS_UWP_NAME "Universal Windows Platform"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_PLAT_WINDOWS_UWP, BOOST_PLAT_WINDOWS_UWP_NAME)

#if !defined(MW_DISABLE_BOOST_DEFAULT_VISIBILITY)
#  if defined(__GNUC__)
#    if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
       /* The matching "push" is in header_prefix.h */
#      pragma GCC visibility pop
#    endif
#  endif
#endif

#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(_MSC_VER)
     /* The matching "push" is in header_prefix.h */
#    pragma warning(pop)
#  endif
#endif
