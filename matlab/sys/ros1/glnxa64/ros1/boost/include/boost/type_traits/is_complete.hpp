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


//  (C) Copyright John Maddock 2017.
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.
 
#ifndef BOOST_TT_IS_COMPLETE_HPP_INCLUDED
#define BOOST_TT_IS_COMPLETE_HPP_INCLUDED

#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/integral_constant.hpp>
#include <boost/type_traits/remove_reference.hpp>
#include <boost/type_traits/is_function.hpp>
#include <boost/type_traits/detail/yes_no_type.hpp>
#include <boost/config/workaround.hpp>
#include <cstddef>

/*
 * CAUTION:
 * ~~~~~~~~
 *
 * THIS TRAIT EXISTS SOLELY TO GENERATE HARD ERRORS WHEN A ANOTHER TRAIT
 * WHICH REQUIRES COMPLETE TYPES AS ARGUMENTS IS PASSED AN INCOMPLETE TYPE
 *
 * DO NOT MAKE GENERAL USE OF THIS TRAIT, AS THE COMPLETENESS OF A TYPE
 * VARIES ACROSS TRANSLATION UNITS AS WELL AS WITHIN A SINGLE UNIT.
 *
*/

namespace mwboost {} namespace boost = mwboost; namespace mwboost {


//
// We will undef this if the trait isn't fully functional:
//
#define BOOST_TT_HAS_WORKING_IS_COMPLETE

#if !defined(BOOST_NO_SFINAE_EXPR) && !BOOST_WORKAROUND(BOOST_MSVC, <= 1900) && !BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40600)

   namespace detail{

      template <std::size_t N>
      struct ok_tag { double d; char c[N]; };

      template <class T>
      ok_tag<sizeof(T)> check_is_complete(int);
      template <class T>
      char check_is_complete(...);
   }

   template <class T> struct is_complete
      : public integral_constant<bool, ::mwboost::is_function<typename mwboost::remove_reference<T>::type>::value || (sizeof(mwboost::detail::check_is_complete<T>(0)) != sizeof(char))> {};

#elif !defined(BOOST_NO_SFINAE) && !defined(BOOST_NO_CXX11_FUNCTION_TEMPLATE_DEFAULT_ARGS) && !BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40500)

   namespace detail
   {

      template <class T>
      struct is_complete_imp
      {
         template <class U, class = decltype(sizeof(mwboost::declval< U >())) >
         static type_traits::yes_type check(U*);

         template <class U>
         static type_traits::no_type check(...);

         static const bool value = sizeof(check<T>(0)) == sizeof(type_traits::yes_type);
      };

} // namespace detail


   template <class T>
   struct is_complete : mwboost::integral_constant<bool, ::mwboost::is_function<typename mwboost::remove_reference<T>::type>::value || ::mwboost::detail::is_complete_imp<T>::value>
   {};
   template <class T>
   struct is_complete<T&> : mwboost::is_complete<T> {};
   
#else

      template <class T> struct is_complete
         : public mwboost::integral_constant<bool, true> {};

#undef BOOST_TT_HAS_WORKING_IS_COMPLETE

#endif

} // namespace mwboost

#endif // BOOST_TT_IS_COMPLETE_HPP_INCLUDED

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
