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

#ifndef BOOST_TT_HAS_TRIVIAL_COPY_HPP_INCLUDED
#define BOOST_TT_HAS_TRIVIAL_COPY_HPP_INCLUDED

#include <cstddef> // size_t
#include <boost/type_traits/intrinsics.hpp>
#include <boost/type_traits/is_pod.hpp>
#include <boost/type_traits/is_reference.hpp>

#if (defined(__GNUC__) && (__GNUC__ * 100 + __GNUC_MINOR__ >= 409)) || defined(BOOST_CLANG) || (defined(__SUNPRO_CC) && defined(BOOST_HAS_TRIVIAL_COPY))
#include <boost/type_traits/is_copy_constructible.hpp>
#define BOOST_TT_TRIVIAL_CONSTRUCT_FIX && is_copy_constructible<T>::value
#else
#define BOOST_TT_TRIVIAL_CONSTRUCT_FIX
#endif

#ifdef BOOST_INTEL
#include <boost/type_traits/add_const.hpp>
#include <boost/type_traits/add_lvalue_reference.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template <typename T> struct has_trivial_copy 
: public integral_constant<bool, 
#ifdef BOOST_HAS_TRIVIAL_COPY
   BOOST_HAS_TRIVIAL_COPY(T) BOOST_TT_TRIVIAL_CONSTRUCT_FIX
#else
   ::mwboost::is_pod<T>::value
#endif
>{};
// Arrays are not explicitly copyable:
template <typename T, std::size_t N> struct has_trivial_copy<T[N]> : public false_type{};
template <typename T> struct has_trivial_copy<T[]> : public false_type{};
// Are volatile types ever trivial?  We don't really know, so assume not:
template <typename T> struct has_trivial_copy<T volatile> : public false_type{};

template <> struct has_trivial_copy<void> : public false_type{};
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
template <> struct has_trivial_copy<void const> : public false_type{};
template <> struct has_trivial_copy<void volatile> : public false_type{};
template <> struct has_trivial_copy<void const volatile> : public false_type{};
#endif

template <class T> struct has_trivial_copy<T&> : public false_type{};
#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES) 
template <class T> struct has_trivial_copy<T&&> : public false_type{};
#endif

template <class T> struct has_trivial_copy_constructor : public has_trivial_copy<T>{};

#undef BOOST_TT_TRIVIAL_CONSTRUCT_FIX

} // namespace mwboost

#endif // BOOST_TT_HAS_TRIVIAL_COPY_HPP_INCLUDED

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
