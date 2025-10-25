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
 * Copyright 2016 Jorge Lodos
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_ERROR_HANDLING_HPP_INCLUDED_
#define BOOST_WINAPI_ERROR_HANDLING_HPP_INCLUDED_

#include <stdarg.h>
#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/get_last_error.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

#if !defined( BOOST_USE_WINDOWS_H )
extern "C" {
#if !defined( BOOST_NO_ANSI_APIS )
BOOST_WINAPI_IMPORT mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
FormatMessageA(
    mwboost::winapi::DWORD_ dwFlags,
    mwboost::winapi::LPCVOID_ lpSource,
    mwboost::winapi::DWORD_ dwMessageId,
    mwboost::winapi::DWORD_ dwLanguageId,
    mwboost::winapi::LPSTR_ lpBuffer,
    mwboost::winapi::DWORD_ nSize,
    va_list *Arguments);
#endif

BOOST_WINAPI_IMPORT_EXCEPT_WM mwboost::winapi::DWORD_ BOOST_WINAPI_WINAPI_CC
FormatMessageW(
    mwboost::winapi::DWORD_ dwFlags,
    mwboost::winapi::LPCVOID_ lpSource,
    mwboost::winapi::DWORD_ dwMessageId,
    mwboost::winapi::DWORD_ dwLanguageId,
    mwboost::winapi::LPWSTR_ lpBuffer,
    mwboost::winapi::DWORD_ nSize,
    va_list *Arguments);

#if BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM
BOOST_WINAPI_IMPORT mwboost::winapi::UINT_ BOOST_WINAPI_WINAPI_CC
SetErrorMode(mwboost::winapi::UINT_ uMode);
#endif
} // extern "C"
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

#if defined( BOOST_USE_WINDOWS_H )

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_ALLOCATE_BUFFER_= FORMAT_MESSAGE_ALLOCATE_BUFFER;
#endif

BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_IGNORE_INSERTS_=  FORMAT_MESSAGE_IGNORE_INSERTS;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_FROM_STRING_=     FORMAT_MESSAGE_FROM_STRING;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_FROM_HMODULE_=    FORMAT_MESSAGE_FROM_HMODULE;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_FROM_SYSTEM_=     FORMAT_MESSAGE_FROM_SYSTEM;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_ARGUMENT_ARRAY_=  FORMAT_MESSAGE_ARGUMENT_ARRAY;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_MAX_WIDTH_MASK_=  FORMAT_MESSAGE_MAX_WIDTH_MASK;

BOOST_CONSTEXPR_OR_CONST WORD_ LANG_NEUTRAL_=                  LANG_NEUTRAL;
BOOST_CONSTEXPR_OR_CONST WORD_ LANG_INVARIANT_=                LANG_INVARIANT;

BOOST_CONSTEXPR_OR_CONST WORD_ SUBLANG_DEFAULT_=               SUBLANG_DEFAULT;    // user default

BOOST_FORCEINLINE BOOST_CONSTEXPR WORD_ MAKELANGID_(WORD_ p, WORD_ s) BOOST_NOEXCEPT
{
    return static_cast< WORD_ >(MAKELANGID(p, s));
}

#if BOOST_WINAPI_PARTITION_DESKTOP
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_FAILCRITICALERRORS_ =     SEM_FAILCRITICALERRORS;
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_NOGPFAULTERRORBOX_ =      SEM_NOGPFAULTERRORBOX;
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_NOALIGNMENTFAULTEXCEPT_ = SEM_NOALIGNMENTFAULTEXCEPT;
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_NOOPENFILEERRORBOX_ =     SEM_NOOPENFILEERRORBOX;
#endif

#else

#if BOOST_WINAPI_PARTITION_APP_SYSTEM
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_ALLOCATE_BUFFER_= 0x00000100;
#endif
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_IGNORE_INSERTS_=  0x00000200;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_FROM_STRING_=     0x00000400;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_FROM_HMODULE_=    0x00000800;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_FROM_SYSTEM_=     0x00001000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_ARGUMENT_ARRAY_=  0x00002000;
BOOST_CONSTEXPR_OR_CONST DWORD_ FORMAT_MESSAGE_MAX_WIDTH_MASK_=  0x000000FF;

BOOST_CONSTEXPR_OR_CONST WORD_ LANG_NEUTRAL_=                  0x00;
BOOST_CONSTEXPR_OR_CONST WORD_ LANG_INVARIANT_=                0x7f;

BOOST_CONSTEXPR_OR_CONST WORD_ SUBLANG_DEFAULT_=               0x01;    // user default

BOOST_FORCEINLINE BOOST_CONSTEXPR WORD_ MAKELANGID_(WORD_ p, WORD_ s) BOOST_NOEXCEPT
{
    return static_cast< WORD_ >((static_cast< DWORD_ >(s) << 10u) | p);
}

#if BOOST_WINAPI_PARTITION_DESKTOP
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_FAILCRITICALERRORS_ =     0x0001;
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_NOGPFAULTERRORBOX_ =      0x0002;
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_NOALIGNMENTFAULTEXCEPT_ = 0x0004;
BOOST_CONSTEXPR_OR_CONST DWORD_ SEM_NOOPENFILEERRORBOX_ =     0x8000;
#endif

#endif

#if !defined( BOOST_NO_ANSI_APIS )
using ::FormatMessageA;
#endif
using ::FormatMessageW;
#if BOOST_WINAPI_PARTITION_DESKTOP || BOOST_WINAPI_PARTITION_SYSTEM
using ::SetErrorMode;
#endif

#if !defined( BOOST_NO_ANSI_APIS )
BOOST_FORCEINLINE DWORD_ format_message(
    DWORD_ dwFlags,
    LPCVOID_ lpSource,
    DWORD_ dwMessageId,
    DWORD_ dwLanguageId,
    LPSTR_ lpBuffer,
    DWORD_ nSize,
    va_list *Arguments)
{
    return ::FormatMessageA(dwFlags, lpSource, dwMessageId, dwLanguageId, lpBuffer, nSize, Arguments);
}
#endif

BOOST_FORCEINLINE DWORD_ format_message(
    DWORD_ dwFlags,
    LPCVOID_ lpSource,
    DWORD_ dwMessageId,
    DWORD_ dwLanguageId,
    LPWSTR_ lpBuffer,
    DWORD_ nSize,
    va_list *Arguments)
{
    return ::FormatMessageW(dwFlags, lpSource, dwMessageId, dwLanguageId, lpBuffer, nSize, Arguments);
}

}
}

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_ERROR_HANDLING_HPP_INCLUDED_

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
