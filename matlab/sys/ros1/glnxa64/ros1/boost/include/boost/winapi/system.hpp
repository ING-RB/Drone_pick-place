#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(__GNUC__)
#    pragma GCC system_header
#  elif defined(_MSC_VER)
     /* The matching "pop" is in header_suffix.h */
#    pragma warning(push, 1)
       /*
        * These suppressions are only here because of the apparent compiler bug:
        * g782945
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
 * Copyright 2010 Vicente J. Botet Escriba
 * Copyright (c) Microsoft Corporation 2014
 * Copyright 2015 Andrey Semashev
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_SYSTEM_HPP_INCLUDED_
#define BOOST_WINAPI_SYSTEM_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

#if !defined( BOOST_USE_WINDOWS_H )
extern "C" {
struct _SYSTEM_INFO;

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::VOID_ BOOST_WINAPI_WINAPI_CC
GetSystemInfo(::_SYSTEM_INFO* lpSystemInfo);
#endif

#if BOOST_WINAPI_PARTITION_APP || BOOST_WINAPI_PARTITION_SYSTEM
#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WINXP
BOOST_WINAPI_IMPORT mwboost::winapi::VOID_ BOOST_WINAPI_WINAPI_CC
GetNativeSystemInfo(::_SYSTEM_INFO* lpSystemInfo);
#endif
#endif
}
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

typedef struct BOOST_MAY_ALIAS _SYSTEM_INFO {
    BOOST_WINAPI_DETAIL_EXTENSION union {
        DWORD_ dwOemId;
        BOOST_WINAPI_DETAIL_EXTENSION struct {
            WORD_ wProcessorArchitecture;
            WORD_ wReserved;
        };
    };
    DWORD_ dwPageSize;
    LPVOID_ lpMinimumApplicationAddress;
    LPVOID_ lpMaximumApplicationAddress;
    DWORD_PTR_ dwActiveProcessorMask;
    DWORD_ dwNumberOfProcessors;
    DWORD_ dwProcessorType;
    DWORD_ dwAllocationGranularity;
    WORD_ wProcessorLevel;
    WORD_ wProcessorRevision;
} SYSTEM_INFO_, *LPSYSTEM_INFO_;

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_FORCEINLINE VOID_ GetSystemInfo(LPSYSTEM_INFO_ lpSystemInfo)
{
    ::GetSystemInfo(reinterpret_cast< ::_SYSTEM_INFO* >(lpSystemInfo));
}
#endif

#if BOOST_WINAPI_PARTITION_APP || BOOST_WINAPI_PARTITION_SYSTEM
#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WINXP
BOOST_FORCEINLINE VOID_ GetNativeSystemInfo(LPSYSTEM_INFO_ lpSystemInfo)
{
    ::GetNativeSystemInfo(reinterpret_cast< ::_SYSTEM_INFO* >(lpSystemInfo));
}
#endif
#endif
}
}

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_SYSTEM_HPP_INCLUDED_

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
