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


//  (C) Copyright John Maddock 2015.
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.

#ifndef BOOST_TT_IS_DEFAULT_CONSTRUCTIBLE_HPP_INCLUDED
#define BOOST_TT_IS_DEFAULT_CONSTRUCTIBLE_HPP_INCLUDED

#include <cstddef> // size_t
#include <boost/type_traits/integral_constant.hpp>
#include <boost/detail/workaround.hpp>
#include <boost/type_traits/is_complete.hpp>
#include <boost/static_assert.hpp>

#if BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40700)
#include <boost/type_traits/is_abstract.hpp>
#endif
#if defined(__clang__) || (defined(__GNUC__) && (__GNUC__ <= 5)) || (defined(BOOST_MSVC) && (BOOST_MSVC == 1800))
#include <utility> // std::pair
#endif

#if !defined(BOOST_NO_CXX11_DECLTYPE) && !BOOST_WORKAROUND(BOOST_MSVC, < 1800) && !BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40500)

#include <boost/type_traits/detail/yes_no_type.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   namespace detail{

      struct is_default_constructible_imp
      {
         template<typename _Tp, typename = decltype(_Tp())>
         static mwboost::type_traits::yes_type test(int);

         template<typename>
         static mwboost::type_traits::no_type test(...);
      };
#if BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40700)
      template<class T, bool b> 
      struct is_default_constructible_abstract_filter
      {
          static const bool value = sizeof(is_default_constructible_imp::test<T>(0)) == sizeof(mwboost::type_traits::yes_type);
      };
      template<class T> 
      struct is_default_constructible_abstract_filter<T, true>
      {
          static const bool value = false;
      };
#endif
   }

#if BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40700)
   template <class T> struct is_default_constructible : public integral_constant<bool, detail::is_default_constructible_abstract_filter<T, mwboost::is_abstract<T>::value>::value>
   {
      BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_default_constructible must be complete types");
   };
#else
   template <class T> struct is_default_constructible : public integral_constant<bool, sizeof(mwboost::detail::is_default_constructible_imp::test<T>(0)) == sizeof(mwboost::type_traits::yes_type)>
   {
      BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_default_constructible must be complete types");
   };
#endif
   template <class T, std::size_t N> struct is_default_constructible<T[N]> : public is_default_constructible<T>{};
   template <class T> struct is_default_constructible<T[]> : public is_default_constructible<T>{};
   template <class T> struct is_default_constructible<T&> : public integral_constant<bool, false>{};
#if defined(__clang__) || (defined(__GNUC__) && (__GNUC__ <= 5))|| (defined(BOOST_MSVC) && (BOOST_MSVC == 1800))
   template <class T, class U> struct is_default_constructible<std::pair<T,U> > : public integral_constant<bool, is_default_constructible<T>::value && is_default_constructible<U>::value>{};
#endif
#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES) 
   template <class T> struct is_default_constructible<T&&> : public integral_constant<bool, false>{};
#endif
   template <> struct is_default_constructible<void> : public integral_constant<bool, false>{};
   template <> struct is_default_constructible<void const> : public integral_constant<bool, false>{};
   template <> struct is_default_constructible<void volatile> : public integral_constant<bool, false>{};
   template <> struct is_default_constructible<void const volatile> : public integral_constant<bool, false>{};

#else

#include <boost/type_traits/is_pod.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   // We don't know how to implement this, note we can not use has_trivial_constructor here
   // because the correct implementation of that trait requires this one:
   template <class T> struct is_default_constructible : public is_pod<T>{};
   template <> struct is_default_constructible<void> : public integral_constant<bool, false>{};
   template <> struct is_default_constructible<void const> : public integral_constant<bool, false>{};
   template <> struct is_default_constructible<void volatile> : public integral_constant<bool, false>{};
   template <> struct is_default_constructible<void const volatile> : public integral_constant<bool, false>{};

#endif

} // namespace mwboost

#endif // BOOST_TT_IS_DEFAULT_CONSTRUCTIBLE_HPP_INCLUDED

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
