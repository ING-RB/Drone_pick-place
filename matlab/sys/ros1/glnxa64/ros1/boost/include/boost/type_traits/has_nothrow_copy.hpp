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

#ifndef BOOST_TT_HAS_NOTHROW_COPY_HPP_INCLUDED
#define BOOST_TT_HAS_NOTHROW_COPY_HPP_INCLUDED

#include <boost/type_traits/intrinsics.hpp>
#include <boost/type_traits/integral_constant.hpp>

#ifdef BOOST_HAS_NOTHROW_COPY

#if defined(BOOST_CLANG) || defined(__GNUC__) || defined(__ghs__) || defined(BOOST_CODEGEARC) || defined(__SUNPRO_CC)
#include <boost/type_traits/is_volatile.hpp>
#include <boost/type_traits/is_copy_constructible.hpp>
#include <boost/type_traits/is_reference.hpp>
#include <boost/type_traits/is_array.hpp>
#ifdef BOOST_INTEL
#include <boost/type_traits/is_pod.hpp>
#endif
#elif defined(BOOST_MSVC) || defined(BOOST_INTEL)
#include <boost/type_traits/has_trivial_copy.hpp>
#include <boost/type_traits/is_array.hpp>
#ifdef BOOST_INTEL
#include <boost/type_traits/add_lvalue_reference.hpp>
#include <boost/type_traits/add_const.hpp>
#endif
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template <class T> struct has_nothrow_copy_constructor : public integral_constant<bool, BOOST_HAS_NOTHROW_COPY(T)>{};

#elif !defined(BOOST_NO_CXX11_NOEXCEPT)

#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/is_copy_constructible.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

namespace detail{

template <class T, bool b>
struct has_nothrow_copy_constructor_imp : public mwboost::integral_constant<bool, false>{};
template <class T>
struct has_nothrow_copy_constructor_imp<T, true> : public mwboost::integral_constant<bool, noexcept(T(mwboost::declval<const T&>()))>{};

}

template <class T> struct has_nothrow_copy_constructor : public detail::has_nothrow_copy_constructor_imp<T, mwboost::is_copy_constructible<T>::value>{};

#else

#include <boost/type_traits/has_trivial_copy.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

template <class T> struct has_nothrow_copy_constructor : public integral_constant<bool, ::mwboost::has_trivial_copy<T>::value>{};

#endif

template <> struct has_nothrow_copy_constructor<void> : public false_type{};
template <class T> struct has_nothrow_copy_constructor<T volatile> : public false_type{};
template <class T> struct has_nothrow_copy_constructor<T&> : public false_type{};
#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES) 
template <class T> struct has_nothrow_copy_constructor<T&&> : public false_type{};
#endif
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
template <> struct has_nothrow_copy_constructor<void const> : public false_type{};
template <> struct has_nothrow_copy_constructor<void volatile> : public false_type{};
template <> struct has_nothrow_copy_constructor<void const volatile> : public false_type{};
#endif

template <class T> struct has_nothrow_copy : public has_nothrow_copy_constructor<T>{};

} // namespace mwboost

#endif // BOOST_TT_HAS_NOTHROW_COPY_HPP_INCLUDED

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
