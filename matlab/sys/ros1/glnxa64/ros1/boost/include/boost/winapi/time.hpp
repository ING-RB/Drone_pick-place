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
 * Copyright 2015, 2017 Andrey Semashev
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_TIME_HPP_INCLUDED_
#define BOOST_WINAPI_TIME_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

#if !defined( BOOST_USE_WINDOWS_H )
extern "C" {
struct _FILETIME;
struct _SYSTEMTIME;

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::VOID_ BOOST_WINAPI_WINAPI_CC
GetSystemTime(::_SYSTEMTIME* lpSystemTime);

#ifdef BOOST_HAS_GETSYSTEMTIMEASFILETIME  // Windows CE does not define GetSystemTimeAsFileTime
BOOST_WINAPI_IMPORT mwboost::winapi::VOID_ BOOST_WINAPI_WINAPI_CC
GetSystemTimeAsFileTime(::_FILETIME* lpSystemTimeAsFileTime);
#endif

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
SystemTimeToFileTime(
    const ::_SYSTEMTIME* lpSystemTime,
    ::_FILETIME* lpFileTime);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
FileTimeToSystemTime(
    const ::_FILETIME* lpFileTime,
    ::_SYSTEMTIME* lpSystemTime);

#if BOOST_WINAPI_PARTITION_APP_SYSTEM

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
FileTimeToLocalFileTime(
    const ::_FILETIME* lpFileTime,
    ::_FILETIME* lpLocalFileTime);

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
LocalFileTimeToFileTime(
    const ::_FILETIME* lpLocalFileTime,
    ::_FILETIME* lpFileTime);

#endif // BOOST_WINAPI_PARTITION_APP_SYSTEM

#if BOOST_WINAPI_PARTITION_DESKTOP_SYSTEM
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
GetTickCount(BOOST_WINAPI_DETAIL_VOID);
#endif // BOOST_WINAPI_PARTITION_DESKTOP_SYSTEM

#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WIN6
BOOST_WINAPI_IMPORT mwboost::winapi::ULONGLONG_ BOOST_WINAPI_WINAPI_CC
GetTickCount64(BOOST_WINAPI_DETAIL_VOID);
#endif

} // extern "C"
#endif // !defined( BOOST_USE_WINDOWS_H )

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

typedef struct BOOST_MAY_ALIAS _FILETIME {
    DWORD_ dwLowDateTime;
    DWORD_ dwHighDateTime;
} FILETIME_, *PFILETIME_, *LPFILETIME_;

typedef struct BOOST_MAY_ALIAS _SYSTEMTIME {
    WORD_ wYear;
    WORD_ wMonth;
    WORD_ wDayOfWeek;
    WORD_ wDay;
    WORD_ wHour;
    WORD_ wMinute;
    WORD_ wSecond;
    WORD_ wMilliseconds;
} SYSTEMTIME_, *PSYSTEMTIME_, *LPSYSTEMTIME_;

#if BOOST_WINAPI_PARTITION_DESKTOP_SYSTEM
using ::GetTickCount;
#endif
#if BOOST_USE_WINAPI_VERSION >= BOOST_WINAPI_VERSION_WIN6
using ::GetTickCount64;
#endif

BOOST_FORCEINLINE VOID_ GetSystemTime(LPSYSTEMTIME_ lpSystemTime)
{
    ::GetSystemTime(reinterpret_cast< ::_SYSTEMTIME* >(lpSystemTime));
}

BOOST_FORCEINLINE BOOL_ SystemTimeToFileTime(const SYSTEMTIME_* lpSystemTime, FILETIME_* lpFileTime)
{
    return ::SystemTimeToFileTime(reinterpret_cast< const ::_SYSTEMTIME* >(lpSystemTime), reinterpret_cast< ::_FILETIME* >(lpFileTime));
}

BOOST_FORCEINLINE BOOL_ FileTimeToSystemTime(const FILETIME_* lpFileTime, SYSTEMTIME_* lpSystemTime)
{
    return ::FileTimeToSystemTime(reinterpret_cast< const ::_FILETIME* >(lpFileTime), reinterpret_cast< ::_SYSTEMTIME* >(lpSystemTime));
}

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_FORCEINLINE BOOL_ FileTimeToLocalFileTime(const FILETIME_* lpFileTime, FILETIME_* lpLocalFileTime)
{
    return ::FileTimeToLocalFileTime(reinterpret_cast< const ::_FILETIME* >(lpFileTime), reinterpret_cast< ::_FILETIME* >(lpLocalFileTime));
}

BOOST_FORCEINLINE BOOL_ LocalFileTimeToFileTime(const FILETIME_* lpLocalFileTime, FILETIME_* lpFileTime)
{
    return ::LocalFileTimeToFileTime(reinterpret_cast< const ::_FILETIME* >(lpLocalFileTime), reinterpret_cast< ::_FILETIME* >(lpFileTime));
}
#endif // BOOST_WINAPI_PARTITION_APP_SYSTEM

#if defined( BOOST_HAS_GETSYSTEMTIMEASFILETIME )
BOOST_FORCEINLINE VOID_ GetSystemTimeAsFileTime(LPFILETIME_ lpSystemTimeAsFileTime)
{
    ::GetSystemTimeAsFileTime(reinterpret_cast< ::_FILETIME* >(lpSystemTimeAsFileTime));
}
#else
// Windows CE does not define GetSystemTimeAsFileTime
BOOST_FORCEINLINE VOID_ GetSystemTimeAsFileTime(FILETIME_* lpFileTime)
{
    mwboost::winapi::SYSTEMTIME_ st;
    mwboost::winapi::GetSystemTime(&st);
    mwboost::winapi::SystemTimeToFileTime(&st, lpFileTime);
}
#endif

}
}

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_TIME_HPP_INCLUDED_

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
