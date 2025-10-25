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

#ifndef BOOST_MP11_FUNCTION_HPP_INCLUDED
#define BOOST_MP11_FUNCTION_HPP_INCLUDED

// Copyright 2015-2019 Peter Dimov.
//
// Distributed under the Boost Software License, Version 1.0.
//
// See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt

#include <boost/mp11/integral.hpp>
#include <boost/mp11/utility.hpp>
#include <boost/mp11/detail/mp_list.hpp>
#include <boost/mp11/detail/mp_count.hpp>
#include <boost/mp11/detail/mp_plus.hpp>
#include <boost/mp11/detail/mp_min_element.hpp>
#include <boost/mp11/detail/mp_void.hpp>
#include <boost/mp11/detail/config.hpp>
#include <type_traits>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
namespace mp11
{

// mp_void<T...>
//   in detail/mp_void.hpp

// mp_and<T...>
#if BOOST_MP11_WORKAROUND( BOOST_MP11_MSVC, < 1910 )

namespace detail
{

template<class... T> struct mp_and_impl;

} // namespace detail

template<class... T> using mp_and = mp_to_bool< typename detail::mp_and_impl<T...>::type >;

namespace detail
{

template<> struct mp_and_impl<>
{
    using type = mp_true;
};

template<class T> struct mp_and_impl<T>
{
    using type = T;
};

template<class T1, class... T> struct mp_and_impl<T1, T...>
{
    using type = mp_eval_if< mp_not<T1>, T1, mp_and, T... >;
};

} // namespace detail

#else

namespace detail
{

template<class L, class E = void> struct mp_and_impl
{
    using type = mp_false;
};

template<class... T> struct mp_and_impl< mp_list<T...>, mp_void<mp_if<T, void>...> >
{
    using type = mp_true;
};

} // namespace detail

template<class... T> using mp_and = typename detail::mp_and_impl<mp_list<T...>>::type;

#endif

// mp_all<T...>
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86355
#if BOOST_MP11_WORKAROUND( BOOST_MP11_MSVC, < 1920 ) || BOOST_MP11_WORKAROUND( BOOST_MP11_GCC, != 0 )

template<class... T> using mp_all = mp_bool< mp_count_if< mp_list<T...>, mp_not >::value == 0 >;

#else

template<class... T> using mp_all = mp_bool< mp_count< mp_list<mp_to_bool<T>...>, mp_false >::value == 0 >;

#endif

// mp_or<T...>
namespace detail
{

template<class... T> struct mp_or_impl;

} // namespace detail

template<class... T> using mp_or = mp_to_bool< typename detail::mp_or_impl<T...>::type >;

namespace detail
{

template<> struct mp_or_impl<>
{
    using type = mp_false;
};

template<class T> struct mp_or_impl<T>
{
    using type = T;
};

template<class T1, class... T> struct mp_or_impl<T1, T...>
{
    using type = mp_eval_if< T1, T1, mp_or, T... >;
};

} // namespace detail

// mp_any<T...>
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86356
#if BOOST_MP11_WORKAROUND( BOOST_MP11_MSVC, < 1920 ) || BOOST_MP11_WORKAROUND( BOOST_MP11_GCC, != 0 )

template<class... T> using mp_any = mp_bool< mp_count_if< mp_list<T...>, mp_to_bool >::value != 0 >;

#else

template<class... T> using mp_any = mp_bool< mp_count< mp_list<mp_to_bool<T>...>, mp_true >::value != 0 >;

#endif

// mp_same<T...>
namespace detail
{

template<class... T> struct mp_same_impl;

template<> struct mp_same_impl<>
{
    using type = mp_true;
};

template<class T1, class... T> struct mp_same_impl<T1, T...>
{
    using type = mp_bool< mp_count<mp_list<T...>, T1>::value == sizeof...(T) >;
};

} // namespace detail

template<class... T> using mp_same = typename detail::mp_same_impl<T...>::type;

// mp_similar<T...>
namespace detail
{

template<class... T> struct mp_similar_impl;

template<> struct mp_similar_impl<>
{
    using type = mp_true;
};

template<class T> struct mp_similar_impl<T>
{
    using type = mp_true;
};

template<class T> struct mp_similar_impl<T, T>
{
    using type = mp_true;
};

template<class T1, class T2> struct mp_similar_impl<T1, T2>
{
    using type = mp_false;
};

template<template<class...> class L, class... T1, class... T2> struct mp_similar_impl<L<T1...>, L<T2...>>
{
    using type = mp_true;
};

template<template<class...> class L, class... T> struct mp_similar_impl<L<T...>, L<T...>>
{
    using type = mp_true;
};

template<class T1, class T2, class T3, class... T> struct mp_similar_impl<T1, T2, T3, T...>
{
    using type = mp_all< typename mp_similar_impl<T1, T2>::type, typename mp_similar_impl<T1, T3>::type, typename mp_similar_impl<T1, T>::type... >;
};

} // namespace detail

template<class... T> using mp_similar = typename detail::mp_similar_impl<T...>::type;

#if BOOST_MP11_GCC
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wsign-compare"
#endif

// mp_less<T1, T2>
template<class T1, class T2> using mp_less = mp_bool<(T1::value < 0 && T2::value >= 0) || ((T1::value < T2::value) && !(T1::value >= 0 && T2::value < 0))>;

#if BOOST_MP11_GCC
# pragma GCC diagnostic pop
#endif

// mp_min<T...>
template<class T1, class... T> using mp_min = mp_min_element<mp_list<T1, T...>, mp_less>;

// mp_max<T...>
template<class T1, class... T> using mp_max = mp_max_element<mp_list<T1, T...>, mp_less>;

} // namespace mp11
} // namespace mwboost

#endif // #ifndef BOOST_MP11_FUNCTION_HPP_INCLUDED

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
