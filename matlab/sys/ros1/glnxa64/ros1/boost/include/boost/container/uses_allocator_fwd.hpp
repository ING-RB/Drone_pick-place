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

//////////////////////////////////////////////////////////////////////////////
//
// (C) Copyright Ion Gaztanaga 2015-2015. Distributed under the Boost
// Software License, Version 1.0. (See accompanying file
// LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org/libs/container for documentation.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef BOOST_CONTAINER_USES_ALLOCATOR_FWD_HPP
#define BOOST_CONTAINER_USES_ALLOCATOR_FWD_HPP

#include <boost/container/detail/workaround.hpp>
#include <boost/container/detail/std_fwd.hpp>

//! \file
//!   This header forward declares mwboost::container::constructible_with_allocator_prefix,
//!   mwboost::container::constructible_with_allocator_suffix and
//!   mwboost::container::uses_allocator. Also defines the following types:

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace container {

#ifndef BOOST_CONTAINER_DOXYGEN_INVOKED

   template <int Dummy = 0>
   struct std_allocator_arg_holder
   {
      static ::std::allocator_arg_t *dummy;
   };

   template <int Dummy>                                             //Silence null-reference compiler warnings
   ::std::allocator_arg_t *std_allocator_arg_holder<Dummy>::dummy = reinterpret_cast< ::std::allocator_arg_t * >(0x1234);

typedef const std::allocator_arg_t & allocator_arg_t;

#else

//! The allocator_arg_t struct is an empty structure type used as a unique type to
//! disambiguate constructor and function overloading. Specifically, several types
//! have constructors with allocator_arg_t as the first argument, immediately followed
//! by an argument of a type that satisfies Allocator requirements
typedef unspecified allocator_arg_t;

#endif   //#ifndef BOOST_CONTAINER_DOXYGEN_INVOKED

//! The `erased_type` struct is an empty struct that serves as a placeholder for a type
//! T in situations where the actual type T is determined at runtime. For example,
//! the nested type, `allocator_type`, is an alias for `erased_type` in classes that
//! use type-erased allocators.
struct erased_type {};

//! A instance of type
//! allocator_arg_t
static allocator_arg_t allocator_arg = BOOST_CONTAINER_DOC1ST(unspecified, *std_allocator_arg_holder<>::dummy);

// @cond

template <class T>
struct constructible_with_allocator_suffix;

template <class T>
struct constructible_with_allocator_prefix;

template <typename T, typename Allocator>
struct uses_allocator;

// @endcond

}} // namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace container {

#endif   //BOOST_CONTAINER_USES_ALLOCATOR_HPP

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
