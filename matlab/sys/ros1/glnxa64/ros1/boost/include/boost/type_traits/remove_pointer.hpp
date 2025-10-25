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

#ifndef BOOST_TT_REMOVE_POINTER_HPP_INCLUDED
#define BOOST_TT_REMOVE_POINTER_HPP_INCLUDED

#include <boost/config.hpp>
#include <boost/config/workaround.hpp>

#if defined(BOOST_MSVC)
#include <boost/type_traits/remove_cv.hpp>
#include <boost/type_traits/is_pointer.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#if BOOST_WORKAROUND(BOOST_MSVC, < 1900)

namespace detail{

   //
   // We need all this crazy indirection because a type such as:
   //
   // T (*const)(U)
   //
   // Does not bind to a <T*> or <T*const> partial specialization with VC10 and earlier
   //
   template <class T> 
   struct remove_pointer_imp
   {
      typedef T type;
   };

   template <class T> 
   struct remove_pointer_imp<T*>
   {
      typedef T type;
   };

   template <class T, bool b> 
   struct remove_pointer_imp3
   {
      typedef typename remove_pointer_imp<typename mwboost::remove_cv<T>::type>::type type;
   };

   template <class T> 
   struct remove_pointer_imp3<T, false>
   {
      typedef T type;
   };

   template <class T> 
   struct remove_pointer_imp2
   {
      typedef typename remove_pointer_imp3<T, ::mwboost::is_pointer<T>::value>::type type;
   };
}

template <class T> struct remove_pointer{ typedef typename mwboost::detail::remove_pointer_imp2<T>::type type; };

#else

template <class T> struct remove_pointer{ typedef T type; };
template <class T> struct remove_pointer<T*>{ typedef T type; };
template <class T> struct remove_pointer<T*const>{ typedef T type; };
template <class T> struct remove_pointer<T*volatile>{ typedef T type; };
template <class T> struct remove_pointer<T*const volatile>{ typedef T type; };

#endif

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES)

   template <class T> using remove_pointer_t = typename remove_pointer<T>::type;

#endif

} // namespace mwboost

#endif // BOOST_TT_REMOVE_POINTER_HPP_INCLUDED

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
