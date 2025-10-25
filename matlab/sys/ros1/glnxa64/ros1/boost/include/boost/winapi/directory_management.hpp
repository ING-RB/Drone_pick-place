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
 * Copyright 2015 Andrey Semashev
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_DIRECTORY_MANAGEMENT_HPP_INCLUDED_
#define BOOST_WINAPI_DIRECTORY_MANAGEMENT_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/get_system_directory.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

#if !defined( BOOST_USE_WINDOWS_H )
extern "C" {
#if !defined( BOOST_NO_ANSI_APIS )
BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
    CreateDirectoryA(mwboost::winapi::LPCSTR_, ::_SECURITY_ATTRIBUTES*);
#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_WINAPI_IMPORT mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
    GetTempPathA(mwboost::winapi::DWORD_ length, mwboost::winapi::LPSTR_ buffer);
#endif
BOOST_WINAPI_IMPORT mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
    RemoveDirectoryA(mwboost::winapi::LPCSTR_);
#endif
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
    CreateDirectoryW(mwboost::winapi::LPCWSTR_, ::_SECURITY_ATTRIBUTES*);
#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
    GetTempPathW(mwboost::winapi::DWORD_ length, mwboost::winapi::LPWSTR_ buffer);
#endif
BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::BOOL_ BOOST_WINAPI_WINAPI_CC
    RemoveDirectoryW(mwboost::winapi::LPCWSTR_);
} // extern "C"
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

#if !defined( BOOST_NO_ANSI_APIS )
#if BOOST_WINAPI_PARTITION_APP_SYSTEM
using ::GetTempPathA;
#endif
using ::RemoveDirectoryA;
#endif
#if BOOST_WINAPI_PARTITION_APP_SYSTEM
using ::GetTempPathW;
#endif
using ::RemoveDirectoryW;

#if !defined( BOOST_NO_ANSI_APIS )
BOOST_FORCEINLINE BOOL_ CreateDirectoryA(LPCSTR_ pPathName, PSECURITY_ATTRIBUTES_ pSecurityAttributes)
{
    return ::CreateDirectoryA(pPathName, reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(pSecurityAttributes));
}
#endif

BOOST_FORCEINLINE BOOL_ CreateDirectoryW(LPCWSTR_ pPathName, PSECURITY_ATTRIBUTES_ pSecurityAttributes)
{
    return ::CreateDirectoryW(pPathName, reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(pSecurityAttributes));
}

#if !defined( BOOST_NO_ANSI_APIS )
BOOST_FORCEINLINE BOOL_ create_directory(LPCSTR_ pPathName, PSECURITY_ATTRIBUTES_ pSecurityAttributes)
{
    return ::CreateDirectoryA(pPathName, reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(pSecurityAttributes));
}
#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_FORCEINLINE DWORD_ get_temp_path(DWORD_ length, LPSTR_ buffer)
{
    return ::GetTempPathA(length, buffer);
}
#endif
BOOST_FORCEINLINE BOOL_ remove_directory(LPCSTR_ pPathName)
{
    return ::RemoveDirectoryA(pPathName);
}
#endif

BOOST_FORCEINLINE BOOL_ create_directory(LPCWSTR_ pPathName, PSECURITY_ATTRIBUTES_ pSecurityAttributes)
{
    return ::CreateDirectoryW(pPathName, reinterpret_cast< ::_SECURITY_ATTRIBUTES* >(pSecurityAttributes));
}
#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_FORCEINLINE DWORD_ get_temp_path(DWORD_ length, LPWSTR_ buffer)
{
    return ::GetTempPathW(length, buffer);
}
#endif
BOOST_FORCEINLINE BOOL_ remove_directory(LPCWSTR_ pPathName)
{
    return ::RemoveDirectoryW(pPathName);
}

} // namespace winapi
} // namespace mwboost

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_DIRECTORY_MANAGEMENT_HPP_INCLUDED_

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
