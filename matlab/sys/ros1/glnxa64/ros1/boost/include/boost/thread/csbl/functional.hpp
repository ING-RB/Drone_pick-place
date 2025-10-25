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

#ifndef BOOST_CSBL_FUNCTIONAL_HPP
#define BOOST_CSBL_FUNCTIONAL_HPP

#include <boost/config.hpp>

#include <functional>

#if defined BOOST_THREAD_USES_BOOST_FUNCTIONAL || defined BOOST_NO_CXX11_HDR_FUNCTIONAL || defined BOOST_NO_CXX11_RVALUE_REFERENCES
#ifndef BOOST_THREAD_USES_BOOST_FUNCTIONAL
#define BOOST_THREAD_USES_BOOST_FUNCTIONAL
#endif
#include <boost/function.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace csbl
  {
#if defined BOOST_THREAD_USES_BOOST_FUNCTIONAL
    using ::mwboost::function;
#else
    // D.8.1, base (deprecated):
    // 20.9.3, reference_wrapper:
    // 20.9.4, arithmetic operations:
    // 20.9.5, comparisons:
    // 20.9.6, logical operations:
    // 20.9.7, bitwise operations:
    // 20.9.8, negators:
    // 20.9.9, bind:
    // D.9, binders (deprecated):
    // D.8.2.1, adaptors (deprecated):
    // D.8.2.2, adaptors (deprecated):
    // 20.9.10, member function adaptors:
    // 20.9.11 polymorphic function wrappers:
    using ::std::function;
    // 20.9.12, hash function primary template:
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
