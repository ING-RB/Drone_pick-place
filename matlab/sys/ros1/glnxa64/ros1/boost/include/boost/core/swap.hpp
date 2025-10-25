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

// Copyright (C) 2007, 2008 Steven Watanabe, Joseph Gauterin, Niels Dekker
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
// For more information, see http://www.boost.org


#ifndef BOOST_CORE_SWAP_HPP
#define BOOST_CORE_SWAP_HPP

// Note: the implementation of this utility contains various workarounds:
// - swap_impl is put outside the boost namespace, to avoid infinite
// recursion (causing stack overflow) when swapping objects of a primitive
// type.
// - swap_impl has a using-directive, rather than a using-declaration,
// because some compilers (including MSVC 7.1, Borland 5.9.3, and
// Intel 8.1) don't do argument-dependent lookup when it has a
// using-declaration instead.
// - mwboost::swap has two template arguments, instead of one, to
// avoid ambiguity when swapping objects of a Boost type that does
// not have its own mwboost::swap overload.

#include <boost/core/enable_if.hpp>
#include <boost/config.hpp>
#if __cplusplus >= 201103L || defined(BOOST_DINKUMWARE_STDLIB)
#include <utility> // for std::swap (C++11)
#else
#include <algorithm> // for std::swap (C++98)
#endif
#include <cstddef> // for std::size_t

namespace mwboost_swap_impl
{
  // we can't use type_traits here

  template<class T> struct is_const { enum _vt { value = 0 }; };
  template<class T> struct is_const<T const> { enum _vt { value = 1 }; };

  template<class T>
  BOOST_GPU_ENABLED
  void swap_impl(T& left, T& right)
  {
    using namespace std;//use std::swap if argument dependent lookup fails
    swap(left,right);
  }

  template<class T, std::size_t N>
  BOOST_GPU_ENABLED
  void swap_impl(T (& left)[N], T (& right)[N])
  {
    for (std::size_t i = 0; i < N; ++i)
    {
      ::mwboost_swap_impl::swap_impl(left[i], right[i]);
    }
  }
}

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  template<class T1, class T2>
  BOOST_GPU_ENABLED
  typename enable_if_c< !mwboost_swap_impl::is_const<T1>::value && !mwboost_swap_impl::is_const<T2>::value >::type
  swap(T1& left, T2& right)
  {
    ::mwboost_swap_impl::swap_impl(left, right);
  }
}

#endif

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
