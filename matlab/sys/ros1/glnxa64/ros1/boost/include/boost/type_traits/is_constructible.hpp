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

#ifndef BOOST_TT_IS_CONSTRUCTIBLE_HPP_INCLUDED
#define BOOST_TT_IS_CONSTRUCTIBLE_HPP_INCLUDED

#include <boost/type_traits/integral_constant.hpp>
#include <boost/detail/workaround.hpp>

#if !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES) && !defined(BOOST_NO_CXX11_DECLTYPE) && !BOOST_WORKAROUND(BOOST_MSVC, < 1800) && !BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40500)

#include <boost/type_traits/is_destructible.hpp>
#include <boost/type_traits/is_default_constructible.hpp>
#include <boost/type_traits/detail/yes_no_type.hpp>
#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/is_complete.hpp>
#include <boost/static_assert.hpp>

#define BOOST_TT_IS_CONSTRUCTIBLE_CONFORMING 1

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   namespace detail{

      struct is_constructible_imp
      {
         template<typename T, typename ...TheArgs, typename = decltype(T(mwboost::declval<TheArgs>()...))>
         static mwboost::type_traits::yes_type test(int);
         template<typename, typename...>
         static mwboost::type_traits::no_type test(...);

         template<typename T, typename Arg, typename = decltype(::new T(mwboost::declval<Arg>()))>
         static mwboost::type_traits::yes_type test1(int);
         template<typename, typename>
         static mwboost::type_traits::no_type test1(...);

         template <typename T>
         static mwboost::type_traits::yes_type ref_test(T);
         template <typename T>
         static mwboost::type_traits::no_type ref_test(...);
      };

   }

   template <class T, class ...Args> struct is_constructible : public integral_constant<bool, sizeof(detail::is_constructible_imp::test<T, Args...>(0)) == sizeof(mwboost::type_traits::yes_type)>
   {
      BOOST_STATIC_ASSERT_MSG(::mwboost::is_complete<T>::value, "The target type must be complete in order to test for constructibility");
   };
   template <class T, class Arg> struct is_constructible<T, Arg> : public integral_constant<bool, is_destructible<T>::value && sizeof(mwboost::detail::is_constructible_imp::test1<T, Arg>(0)) == sizeof(mwboost::type_traits::yes_type)>
   {
      BOOST_STATIC_ASSERT_MSG(::mwboost::is_complete<T>::value, "The target type must be complete in order to test for constructibility");
   };
   template <class Ref, class Arg> struct is_constructible<Ref&, Arg> : public integral_constant<bool, sizeof(detail::is_constructible_imp::ref_test<Ref&>(mwboost::declval<Arg>())) == sizeof(mwboost::type_traits::yes_type)>{};
   template <class Ref, class Arg> struct is_constructible<Ref&&, Arg> : public integral_constant<bool, sizeof(detail::is_constructible_imp::ref_test<Ref&&>(mwboost::declval<Arg>())) == sizeof(mwboost::type_traits::yes_type)>{};

   template <> struct is_constructible<void> : public false_type{};
   template <> struct is_constructible<void const> : public false_type{};
   template <> struct is_constructible<void const volatile> : public false_type{};
   template <> struct is_constructible<void volatile> : public false_type{};

   template <class T> struct is_constructible<T> : public is_default_constructible<T>{};

#else

#include <boost/type_traits/is_convertible.hpp>
#include <boost/type_traits/is_default_constructible.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   // We don't know how to implement this:
   template <class T, class U = void> struct is_constructible : public is_convertible<U, T>{};
   template <class T> struct is_constructible<T, void> : public is_default_constructible<T>{};
   template <> struct is_constructible<void, void> : public false_type{};
   template <> struct is_constructible<void const, void> : public false_type{};
   template <> struct is_constructible<void const volatile, void> : public false_type{};
   template <> struct is_constructible<void volatile, void> : public false_type{};
   template <class Ref> struct is_constructible<Ref&, void> : public false_type{};
#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
   template <class Ref> struct is_constructible<Ref&&, void> : public false_type{};
#endif
#endif

} // namespace mwboost

#endif // BOOST_TT_IS_CONSTRUCTIBLE_HPP_INCLUDED

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
