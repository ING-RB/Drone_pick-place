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

#ifndef BOOST_TT_IS_POD_HPP_INCLUDED
#define BOOST_TT_IS_POD_HPP_INCLUDED

#include <cstddef> // size_t
#include <boost/type_traits/detail/config.hpp>
#include <boost/type_traits/is_void.hpp>
#include <boost/type_traits/is_scalar.hpp>
#include <boost/type_traits/intrinsics.hpp>

#ifdef __SUNPRO_CC
#include <boost/type_traits/is_function.hpp>
#endif

#include <cstddef>

#ifndef BOOST_IS_POD
#define BOOST_INTERNAL_IS_POD(T) false
#else
#define BOOST_INTERNAL_IS_POD(T) BOOST_IS_POD(T)
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

// forward declaration, needed by 'is_pod_array_helper' template below
template< typename T > struct is_POD;

template <typename T> struct is_pod
: public integral_constant<bool, ::mwboost::is_scalar<T>::value || ::mwboost::is_void<T>::value || BOOST_INTERNAL_IS_POD(T)>
{};

#if !defined(BOOST_NO_ARRAY_TYPE_SPECIALIZATIONS)
template <typename T, std::size_t sz> struct is_pod<T[sz]> : public is_pod<T>{};
#endif


// the following help compilers without partial specialization support:
template<> struct is_pod<void> : public true_type{};

#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
template<> struct is_pod<void const> : public true_type{};
template<> struct is_pod<void const volatile> : public true_type{};
template<> struct is_pod<void volatile> : public true_type{};
#endif

template<class T> struct is_POD : public is_pod<T>{};

} // namespace mwboost

#undef BOOST_INTERNAL_IS_POD

#endif // BOOST_TT_IS_POD_HPP_INCLUDED

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
