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

// Copyright (C) 2013 Vicente J. Botet Escriba
//
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// 2013/10 Vicente J. Botet Escriba
//   Creation.

#ifndef BOOST_CSBL_TUPLE_HPP
#define BOOST_CSBL_TUPLE_HPP

#include <boost/config.hpp>

#if defined BOOST_THREAD_USES_BOOST_TUPLE || defined BOOST_NO_CXX11_HDR_TUPLE || defined BOOST_NO_CXX11_RVALUE_REFERENCES
#include <boost/tuple/tuple.hpp>
#ifndef BOOST_THREAD_USES_BOOST_TUPLE
#define BOOST_THREAD_USES_BOOST_TUPLE
#endif

#else
#include <tuple>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace csbl
  {
#if defined BOOST_THREAD_USES_BOOST_TUPLE
    using ::mwboost::tuple;
    using ::mwboost::get;
    using ::mwboost::make_tuple;
    //using ::mwboost::tuple_size;
#else
    // 20.4.2, class template tuple:
    using ::std::tuple;
    using ::std::get;
    using ::std::make_tuple;
    using ::std::tuple_size;
    // 20.4.2.4, tuple creation functions:
    // 20.4.2.5, tuple helper classes:
    // 20.4.2.6, element access:
    // 20.4.2.7, relational operators:
    // 20.4.2.8, allocator-related traits
    // 20.4.2.9, specialized algorithms:
#endif

  }
}
#endif // header

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
