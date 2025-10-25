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

// Copyright (C) 2003, Fernando Luis Cacciola Carballal.
// Copyright (C) 2014, 2015 Andrzej Krzemienski.
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org/libs/optional for documentation.
//
// You are welcome to contact the author at:
//  fernando_cacciola@hotmail.com
//
#ifndef BOOST_NONE_17SEP2003_HPP
#define BOOST_NONE_17SEP2003_HPP

#include "boost/config.hpp"
#include "boost/none_t.hpp"

// NOTE: Borland users have to include this header outside any precompiled headers
// (bcc<=5.64 cannot include instance data in a precompiled header)
//  -- * To be verified, now that there's no unnamed namespace

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#ifdef BOOST_OPTIONAL_USE_OLD_DEFINITION_OF_NONE

BOOST_INLINE_VARIABLE none_t BOOST_CONSTEXPR_OR_CONST none = (static_cast<none_t>(0)) ;

#elif defined BOOST_OPTIONAL_USE_SINGLETON_DEFINITION_OF_NONE

namespace detail { namespace optional_detail {

  // the trick here is to make mwboost::none defined once as a global but in a header file
  template <typename T>
  struct none_instance
  {
    static const T instance;
  };

  template <typename T>
  const T none_instance<T>::instance = T(); // global, but because 'tis a template, no cpp file required

} } // namespace detail::optional_detail


namespace {
  // TU-local
  const none_t& none = detail::optional_detail::none_instance<none_t>::instance;
}

#else

BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST none_t none ((none_t::init_tag()));

#endif // older definitions

} // namespace mwboost

#endif // header guard

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
