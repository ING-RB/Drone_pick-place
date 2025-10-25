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

//  boost/chrono/utility/to_string.hpp
//
//  Copyright 2011 Vicente J. Botet Escriba
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).

#ifndef BOOST_CHRONO_UTILITY_TO_STRING_HPP
#define BOOST_CHRONO_UTILITY_TO_STRING_HPP

#include <boost/chrono/config.hpp>
#include <string>
#include <sstream>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace chrono
  {
    template <typename CharT, typename T>
    std::basic_string<CharT> to_basic_string(T const&v) {
      std::basic_stringstream<CharT> sstr;
      sstr << v;
      return sstr.str();
    }

    template <typename T>
    std::string to_string(T const&v) {
      return to_basic_string<char>(v);
    }
#ifndef BOOST_NO_STD_WSTRING
    template <typename T>
    std::wstring to_wstring(T const&v) {
      return to_basic_string<wchar_t>(v);
    }
#endif
#if BOOST_CHRONO_HAS_UNICODE_SUPPORT
    template <typename T>
    std::basic_string<char16_t> to_u16string(T const&v) {
      return to_basic_string<char16_t>(v);
    }
    template <typename T>
    std::basic_string<char32_t> to_u32string(T const&v) {
      return to_basic_string<char32_t>(v);
    }
#endif
  } // chrono

} // boost

#endif  // header

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
