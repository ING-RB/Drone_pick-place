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

#ifndef BOOST_TT_HAS_NOTHROW_ASSIGN_HPP_INCLUDED
#define BOOST_TT_HAS_NOTHROW_ASSIGN_HPP_INCLUDED

#include <cstddef> // size_t
#include <boost/type_traits/integral_constant.hpp>
#include <boost/type_traits/intrinsics.hpp>

#if !defined(BOOST_HAS_NOTHROW_ASSIGN) || defined(BOOST_MSVC) || defined(BOOST_INTEL)
#include <boost/type_traits/has_trivial_assign.hpp>
#if !defined(BOOST_NO_CXX11_NOEXCEPT) && !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/is_const.hpp>
#include <boost/type_traits/is_volatile.hpp>
#include <boost/type_traits/is_reference.hpp>
#include <boost/type_traits/is_assignable.hpp>
#include <boost/type_traits/add_reference.hpp>
#include <boost/type_traits/remove_reference.hpp>
#endif
#endif
#if defined(__GNUC__) || defined(__SUNPRO_CC) || defined(__clang__)
#include <boost/type_traits/is_const.hpp>
#include <boost/type_traits/is_volatile.hpp>
#include <boost/type_traits/is_assignable.hpp>
#include <boost/type_traits/is_array.hpp>
#ifdef BOOST_INTEL
#include <boost/type_traits/is_pod.hpp>
#endif
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#if !defined(BOOST_HAS_NOTHROW_ASSIGN) && !defined(BOOST_NO_CXX11_NOEXCEPT) && !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)

   namespace detail
   {
      template <class T, bool b1, bool b2> struct has_nothrow_assign_imp{ static const bool value = false; };
      template <class T>          struct has_nothrow_assign_imp<T, false, true>{ static const bool value = noexcept(mwboost::declval<typename add_reference<T>::type>() = mwboost::declval<typename add_reference<T const>::type>()); };
      template <class T, std::size_t N> struct has_nothrow_assign_imp<T[N], false, true>{ static const bool value = has_nothrow_assign_imp<T, false, true>::value; };
      template <class T>          struct has_nothrow_assign_imp<T[], false, true>{ static const bool value = has_nothrow_assign_imp<T, false, true>::value; };
   }

#endif

   template <class T>
   struct has_nothrow_assign : public integral_constant < bool,
#ifndef BOOST_HAS_NOTHROW_ASSIGN
#if !defined(BOOST_NO_CXX11_NOEXCEPT) && !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
      // Portable C++11 version:
      detail::has_nothrow_assign_imp<T, 
      (is_const<typename remove_reference<T>::type>::value || is_volatile<typename remove_reference<T>::type>::value || is_reference<T>::value), 
      is_assignable<typename add_reference<T>::type, typename add_reference<const T>::type>::value
      >::value
#else
      ::mwboost::has_trivial_assign<T>::value
#endif
#else
      BOOST_HAS_NOTHROW_ASSIGN(T)
#endif
   > {};

template <class T, std::size_t N> struct has_nothrow_assign <T[N]> : public has_nothrow_assign<T> {};
template <> struct has_nothrow_assign<void> : public false_type{};
template <class T> struct has_nothrow_assign<T volatile> : public false_type{};
template <class T> struct has_nothrow_assign<T&> : public false_type{};
#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
template <class T> struct has_nothrow_assign<T&&> : public false_type{};
#endif
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
template <> struct has_nothrow_assign<void const> : public false_type{};
template <> struct has_nothrow_assign<void const volatile> : public false_type{};
template <> struct has_nothrow_assign<void volatile> : public false_type{};
#endif

} // namespace mwboost

#endif // BOOST_TT_HAS_NOTHROW_ASSIGN_HPP_INCLUDED

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
