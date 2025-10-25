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

#ifndef BOOST_TT_IS_ASSIGNABLE_HPP_INCLUDED
#define BOOST_TT_IS_ASSIGNABLE_HPP_INCLUDED

#include <cstddef> // size_t
#include <boost/type_traits/integral_constant.hpp>
#include <boost/detail/workaround.hpp>
#include <boost/type_traits/is_complete.hpp>
#include <boost/static_assert.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   template <class T, class U = T> struct is_assignable;

}

#if !defined(BOOST_NO_CXX11_DECLTYPE) && !BOOST_WORKAROUND(BOOST_MSVC, < 1800)

#include <boost/type_traits/detail/yes_no_type.hpp>
#include <boost/type_traits/declval.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   namespace detail{

      struct is_assignable_imp
      {
         template<typename T, typename U, typename = decltype(mwboost::declval<T>() = mwboost::declval<U>())>
         static mwboost::type_traits::yes_type test(int);

         template<typename, typename>
         static mwboost::type_traits::no_type test(...);
      };

   }

   template <class T, class U> struct is_assignable : public integral_constant<bool, sizeof(detail::is_assignable_imp::test<T, U>(0)) == sizeof(mwboost::type_traits::yes_type)>
   {
      BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_assignable must be complete types");
   };
   template <class T, std::size_t N, class U> struct is_assignable<T[N], U> : public is_assignable<T, U>{};
   template <class T, std::size_t N, class U> struct is_assignable<T(&)[N], U> : public is_assignable<T&, U>{};
   template <class T, class U> struct is_assignable<T[], U> : public is_assignable<T, U>{};
   template <class T, class U> struct is_assignable<T(&)[], U> : public is_assignable<T&, U>{};
   template <class U> struct is_assignable<void, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void const, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void volatile, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void const volatile, U> : public integral_constant<bool, false>{};

#else

#include <boost/type_traits/has_trivial_assign.hpp>
#include <boost/type_traits/remove_reference.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

   // We don't know how to implement this:
   template <class T, class U> struct is_assignable : public integral_constant<bool, false>
   {
      BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_assignable must be complete types");
   };
   template <class T, class U> struct is_assignable<T&, U> : public integral_constant<bool, is_pod<T>::value && is_pod<typename remove_reference<U>::type>::value>{};
   template <class T, class U> struct is_assignable<const T&, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void const, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void volatile, U> : public integral_constant<bool, false>{};
   template <class U> struct is_assignable<void const volatile, U> : public integral_constant<bool, false>{};
   /*
   template <> struct is_assignable<void, void> : public integral_constant<bool, false>{};
   template <> struct is_assignable<void const, void const> : public integral_constant<bool, false>{};
   template <> struct is_assignable<void volatile, void volatile> : public integral_constant<bool, false>{};
   template <> struct is_assignable<void const volatile, void const volatile> : public integral_constant<bool, false>{};
   */
#endif

} // namespace mwboost

#endif // BOOST_TT_IS_ASSIGNABLE_HPP_INCLUDED

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
