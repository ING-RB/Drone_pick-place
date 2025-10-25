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
 * Copyright 2015, 2017 Andrey Semashev
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_HEAP_MEMORY_HPP_INCLUDED_
#define BOOST_WINAPI_HEAP_MEMORY_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

#if !defined( BOOST_USE_WINDOWS_H )
#undef HeapAlloc
extern "C" {

#if BOOST_WINAPI_PARTITION_DESKTOP_SYSTEM
BOOST_WINAPI_IMPORT mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
GetProcessHeaps(mwboost::winapi::DWORD_ NumberOfHeaps, mwboost::winapi::PHANDLE_ ProcessHeaps);
#endif // BOOST_WINAPI_PARTITION_DESKTOP_SYSTEM

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::HANDLE_ BOOST_WINAPI_WINAPI_CC
GetProcessHeap(BOOST_WINAPI_DETAIL_VOID);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::LPVOID_ BOOST_WINAPI_WINAPI_CC
HeapAlloc(
    mwboost::winapi::HANDLE_ hHeap,
    mwboost::winapi::DWORD_ dwFlags,
    mwboost::winapi::SIZE_T_ dwBytes);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
HeapFree(
    mwboost::winapi::HANDLE_ hHeap,
    mwboost::winapi::DWORD_ dwFlags,
    mwboost::winapi::LPVOID_ lpMem);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::LPVOID_ BOOST_WINAPI_WINAPI_CC
HeapReAlloc(
    mwboost::winapi::HANDLE_ hHeap,
    mwboost::winapi::DWORD_ dwFlags,
    mwboost::winapi::LPVOID_ lpMem,
    mwboost::winapi::SIZE_T_ dwBytes);

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::HANDLE_ BOOST_WINAPI_WINAPI_CC
HeapCreate(
    mwboost::winapi::DWORD_ flOptions,
    mwboost::winapi::SIZE_T_ dwInitialSize,
    mwboost::winapi::SIZE_T_ dwMaximumSize);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
HeapDestroy(mwboost::winapi::HANDLE_ hHeap);
#endif // BOOST_WINAPI_PARTITION_APP_SYSTEM

} // extern "C"
#endif // !defined( BOOST_USE_WINDOWS_H )

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

#if BOOST_WINAPI_PARTITION_DESKTOP_SYSTEM
using ::GetProcessHeaps;
#endif

using ::GetProcessHeap;
using ::HeapAlloc;
using ::HeapFree;
using ::HeapReAlloc;

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
using ::HeapCreate;
using ::HeapDestroy;
#endif

}
}

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_HEAP_MEMORY_HPP_INCLUDED_

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
