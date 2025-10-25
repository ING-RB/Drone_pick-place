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
 * Copyright 2016 Andrey Semashev
 *
 * Distributed under the Boost Software License, Version 1.0.
 * See http://www.boost.org/LICENSE_1_0.txt
 */

#ifndef BOOST_WINAPI_LIMITS_HPP_INCLUDED_
#define BOOST_WINAPI_LIMITS_HPP_INCLUDED_

#include <boost/winapi/basic_types.hpp>
#include <boost/winapi/detail/header.hpp>

#ifdef BOOST_HAS_PRAGMA_ONCE
#pragma once
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace winapi {

#if defined( BOOST_USE_WINDOWS_H )

BOOST_CONSTEXPR_OR_CONST DWORD_ MAX_PATH_ = MAX_PATH;

#else

BOOST_CONSTEXPR_OR_CONST DWORD_ MAX_PATH_ = 260;

#endif

#if defined( BOOST_USE_WINDOWS_H ) && !defined( BOOST_WINAPI_IS_MINGW )

BOOST_CONSTEXPR_OR_CONST DWORD_ UNICODE_STRING_MAX_BYTES_ = UNICODE_STRING_MAX_BYTES;
BOOST_CONSTEXPR_OR_CONST DWORD_ UNICODE_STRING_MAX_CHARS_ = UNICODE_STRING_MAX_CHARS;

#else

BOOST_CONSTEXPR_OR_CONST DWORD_ UNICODE_STRING_MAX_BYTES_ = 65534;
BOOST_CONSTEXPR_OR_CONST DWORD_ UNICODE_STRING_MAX_CHARS_ = 32767;

#endif

BOOST_CONSTEXPR_OR_CONST DWORD_ max_path = MAX_PATH_;
BOOST_CONSTEXPR_OR_CONST DWORD_ unicode_string_max_bytes = UNICODE_STRING_MAX_BYTES_;
BOOST_CONSTEXPR_OR_CONST DWORD_ unicode_string_max_chars = UNICODE_STRING_MAX_CHARS_;

}
}

#include <boost/winapi/detail/footer.hpp>

#endif // BOOST_WINAPI_LIMITS_HPP_INCLUDED_

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
