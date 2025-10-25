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

//-----------------------------------------------------------------------------
// boost variant/recursive_wrapper_fwd.hpp header file
// See http://www.boost.org for updates, documentation, and revision history.
//-----------------------------------------------------------------------------
//
// Copyright (c) 2002 Eric Friedman, Itay Maman
// Copyright (c) 2016-2022 Antony Polukhin
//
// Portions Copyright (C) 2002 David Abrahams
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_VARIANT_RECURSIVE_WRAPPER_FWD_HPP
#define BOOST_VARIANT_RECURSIVE_WRAPPER_FWD_HPP

#include <boost/mpl/bool.hpp>
#include <boost/mpl/aux_/config/ctps.hpp>
#include <boost/mpl/aux_/lambda_support.hpp>
#include <boost/type_traits/integral_constant.hpp>
#include <boost/type_traits/is_constructible.hpp>
#include <boost/type_traits/is_nothrow_move_constructible.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

//////////////////////////////////////////////////////////////////////////
// class template recursive_wrapper
//
// Enables recursive types in templates by breaking cyclic dependencies.
//
// For example:
//
//   class my;
//
//   typedef variant< int, recursive_wrapper<my> > var;
//
//   class my {
//     var var_;
//     ...
//   };
//
template <typename T> class recursive_wrapper;


///////////////////////////////////////////////////////////////////////////////
// metafunction is_constructible partial specializations.
//
// recursive_wrapper<T> is constructible only from T and recursive_wrapper<T>.
//
template <class T>          struct is_constructible<recursive_wrapper<T>, T>                            : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, const T>                      : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, T&>                           : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, const T&>                     : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, recursive_wrapper<T> >        : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, const recursive_wrapper<T> >  : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, recursive_wrapper<T>& >       : mwboost::true_type{};
template <class T>          struct is_constructible<recursive_wrapper<T>, const recursive_wrapper<T>& > : mwboost::true_type{};

template <class T, class U> struct is_constructible<recursive_wrapper<T>, U >                           : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, const U >                     : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, U& >                          : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, const U& >                    : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, recursive_wrapper<U> >        : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, const recursive_wrapper<U> >  : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, recursive_wrapper<U>& >       : mwboost::false_type{};
template <class T, class U> struct is_constructible<recursive_wrapper<T>, const recursive_wrapper<U>& > : mwboost::false_type{};

// recursive_wrapper is not nothrow move constructible, because it's constructor does dynamic memory allocation.
// This specialisation is required to workaround GCC6 issue: https://svn.boost.org/trac/boost/ticket/12680
template <class T> struct is_nothrow_move_constructible<recursive_wrapper<T> > : mwboost::false_type{};

///////////////////////////////////////////////////////////////////////////////
// metafunction is_recursive_wrapper (modeled on code by David Abrahams)
//
// True if specified type matches recursive_wrapper<T>.
//

namespace detail {


template <typename T>
struct is_recursive_wrapper_impl
    : mpl::false_
{
};

template <typename T>
struct is_recursive_wrapper_impl< recursive_wrapper<T> >
    : mpl::true_
{
};


} // namespace detail

template< typename T > struct is_recursive_wrapper
    : public ::mwboost::integral_constant<bool,(::mwboost::detail::is_recursive_wrapper_impl<T>::value)>
{
public:
    BOOST_MPL_AUX_LAMBDA_SUPPORT(1,is_recursive_wrapper,(T))
};

///////////////////////////////////////////////////////////////////////////////
// metafunction unwrap_recursive
//
// If specified type T matches recursive_wrapper<U>, then U; else T.
//


template <typename T>
struct unwrap_recursive
{
    typedef T type;

    BOOST_MPL_AUX_LAMBDA_SUPPORT(1,unwrap_recursive,(T))
};

template <typename T>
struct unwrap_recursive< recursive_wrapper<T> >
{
    typedef T type;

    BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(1,unwrap_recursive,(T))
};


} // namespace mwboost

#endif // BOOST_VARIANT_RECURSIVE_WRAPPER_FWD_HPP

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
