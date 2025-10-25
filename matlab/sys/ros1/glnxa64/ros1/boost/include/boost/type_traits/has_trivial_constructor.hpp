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


//  (C) Copyright Steve Cleary, Beman Dawes, Howard Hinnant & John Maddock 2000.
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.

#ifndef BOOST_TT_HAS_TRIVIAL_CONSTRUCTOR_HPP_INCLUDED
#define BOOST_TT_HAS_TRIVIAL_CONSTRUCTOR_HPP_INCLUDED

#include <boost/type_traits/intrinsics.hpp>
#include <boost/type_traits/is_pod.hpp>
#include <boost/type_traits/is_default_constructible.hpp>

#ifdef BOOST_HAS_TRIVIAL_CONSTRUCTOR
#ifdef BOOST_HAS_SGI_TYPE_TRAITS
#include <boost/type_traits/is_same.hpp>
#elif defined(__GNUC__) || defined(__SUNPRO_CC)
#include <boost/type_traits/is_volatile.hpp>
#ifdef BOOST_INTEL
#include <boost/type_traits/is_pod.hpp>
#endif
#endif
#endif


#if (defined(__GNUC__) && (__GNUC__ * 100 + __GNUC_MINOR__ >= 409)) || defined(BOOST_CLANG) || (defined(__SUNPRO_CC) && defined(BOOST_HAS_TRIVIAL_CONSTRUCTOR))
#include <boost/type_traits/is_default_constructible.hpp>
#define BOOST_TT_TRIVIAL_CONSTRUCT_FIX && is_default_constructible<T>::value
#else
//
// Mot all compilers, particularly older GCC versions can handle the fix above.
#define BOOST_TT_TRIVIAL_CONSTRUCT_FIX
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template <typename T> struct has_trivial_constructor
#ifdef BOOST_HAS_TRIVIAL_CONSTRUCTOR
   : public integral_constant <bool, ((::mwboost::is_pod<T>::value || BOOST_HAS_TRIVIAL_CONSTRUCTOR(T)) BOOST_TT_TRIVIAL_CONSTRUCT_FIX)>{};
#else
   : public integral_constant <bool, ::mwboost::is_pod<T>::value>{};
#endif

template <> struct has_trivial_constructor<void> : public mwboost::false_type{};
template <> struct has_trivial_constructor<void const> : public mwboost::false_type{};
template <> struct has_trivial_constructor<void const volatile> : public mwboost::false_type{};
template <> struct has_trivial_constructor<void volatile> : public mwboost::false_type{};

template <class T> struct has_trivial_default_constructor : public has_trivial_constructor<T> {};

#undef BOOST_TT_TRIVIAL_CONSTRUCT_FIX

} // namespace mwboost

#endif // BOOST_TT_HAS_TRIVIAL_CONSTRUCTOR_HPP_INCLUDED

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
