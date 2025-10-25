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


//  (C) Copyright Dave Abrahams, Steve Cleary, Beman Dawes, Howard
//  Hinnant & John Maddock 2000.  
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.


// Some fixes for is_array are based on a newsgroup posting by Jonathan Lundquist.


#ifndef BOOST_TT_IS_ARRAY_HPP_INCLUDED
#define BOOST_TT_IS_ARRAY_HPP_INCLUDED

#include <boost/type_traits/integral_constant.hpp>
#include <cstddef> // size_t

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#if defined( BOOST_CODEGEARC )
   template <class T> struct is_array : public integral_constant<bool, __is_array(T)> {};
#else
   template <class T> struct is_array : public false_type {};
#if !defined(BOOST_NO_ARRAY_TYPE_SPECIALIZATIONS)
   template <class T, std::size_t N> struct is_array<T[N]> : public true_type {};
   template <class T, std::size_t N> struct is_array<T const[N]> : public true_type{};
   template <class T, std::size_t N> struct is_array<T volatile[N]> : public true_type{};
   template <class T, std::size_t N> struct is_array<T const volatile[N]> : public true_type{};
#if !BOOST_WORKAROUND(BOOST_BORLANDC, < 0x600) && !defined(__IBMCPP__) &&  !BOOST_WORKAROUND(__DMC__, BOOST_TESTED_AT(0x840))
   template <class T> struct is_array<T[]> : public true_type{};
   template <class T> struct is_array<T const[]> : public true_type{};
   template <class T> struct is_array<T const volatile[]> : public true_type{};
   template <class T> struct is_array<T volatile[]> : public true_type{};
#endif
#endif

#endif

} // namespace mwboost

#endif // BOOST_TT_IS_ARRAY_HPP_INCLUDED

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
