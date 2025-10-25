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
 * Copyright 2020 Andrey Semashev
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_GET_PROC_ADDRESS_HPP_INCLUDED_
#define BOOST_WINAPI_GET_PROC_ADDRESS_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

#if BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM

#include <boost/winapi/detail/header.hpp>

#if !defined(BOOST_USE_WINDOWS_H)
namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace winapi {
#ifdef _WIN64
typedef INT_PTR_ (BOOST_WINAPI_WINAPI_CC *FARPROC_)();
typedef INT_PTR_ (BOOST_WINAPI_WINAPI_CC *NEARPROC_)();
typedef INT_PTR_ (BOOST_WINAPI_WINAPI_CC *PROC_)();
#else
typedef int (BOOST_WINAPI_WINAPI_CC *FARPROC_)();
typedef int (BOOST_WINAPI_WINAPI_CC *NEARPROC_)();
typedef int (BOOST_WINAPI_WINAPI_CC *PROC_)();
#endif // _WIN64
}} // namespace mwboost::winapi

extern "C" {
#if !defined(UNDER_CE)
BOOST_WINAPI_IMPORT mwboost::winapi::FARPROC_ BOOST_WINAPI_WINAPI_CC
GetProcAddress(mwboost::winapi::HMODULE_ hModule, mwboost::winapi::LPCSTR_ lpProcName);
#else
// On Windows CE there are two functions: GetProcAddressA (since Windows CE 3.0) and GetProcAddressW.
// GetProcAddress is a macro that is _always_ defined to GetProcAddressW.
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::FARPROC_ BOOST_WINAPI_WINAPI_CC
GetProcAddressA(mwboost::winapi::HMODULE_ hModule, mwboost::winapi::LPCSTR_ lpProcName);
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::FARPROC_ BOOST_WINAPI_WINAPI_CC
GetProcAddressW(mwboost::winapi::HMODULE_ hModule, mwboost::winapi::LPCWSTR_ lpProcName);
#endif
} // extern "C"
#endif // !defined(BOOST_USE_WINDOWS_H)

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

#if defined(BOOST_USE_WINDOWS_H)
typedef ::FARPROC FARPROC_;
typedef ::NEARPROC NEARPROC_;
typedef ::PROC PROC_;
#endif // defined(BOOST_USE_WINDOWS_H)

#if !defined(UNDER_CE)
// For backward compatibility, don't use directly. Use get_proc_address instead.
using ::GetProcAddress;
#else
using ::GetProcAddressA;
using ::GetProcAddressW;
#endif

BOOST_FORCEINLINE FARPROC_ get_proc_address(HMODULE_ hModule, LPCSTR_ lpProcName)
{
#if !defined(UNDER_CE)
    return ::GetProcAddress(hModule, lpProcName);
#else
    return ::GetProcAddressA(hModule, lpProcName);
#endif
}

} // namespace winapi
} // namespace mwboost

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM
#endif // BOOST_WINAPI_GET_PROC_ADDRESS_HPP_INCLUDED_

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
