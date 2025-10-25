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

#ifndef BOOST_TYPE_TRAITS_COMMON_TYPE_HPP_INCLUDED
#define BOOST_TYPE_TRAITS_COMMON_TYPE_HPP_INCLUDED

//
//  Copyright 2015 Peter Dimov
//
//  Distributed under the Boost Software License, Version 1.0.
//  See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt
//

#include <boost/config.hpp>
#include <boost/type_traits/decay.hpp>
#include <boost/type_traits/declval.hpp>
#include <boost/detail/workaround.hpp>
#include <boost/type_traits/is_complete.hpp>
#include <boost/type_traits/is_void.hpp>
#include <boost/type_traits/is_array.hpp>
#include <boost/static_assert.hpp>

#if defined(BOOST_NO_CXX11_DECLTYPE)
#include <boost/type_traits/detail/common_type_impl.hpp>
#endif

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES) && !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES)
#include <boost/type_traits/detail/mp_defer.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

// variadic common_type

#if !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES)

template<class... T> struct common_type
{
};

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES)

template<class... T> using common_type_t = typename common_type<T...>::type;

namespace type_traits_detail
{

template<class T1, class T2, class... T> using common_type_fold = common_type_t<common_type_t<T1, T2>, T...>;

} // namespace type_traits_detail

template<class T1, class T2, class... T>
struct common_type<T1, T2, T...>: type_traits_detail::mp_defer<type_traits_detail::common_type_fold, T1, T2, T...>
{
};

#else

template<class T1, class T2, class... T>
struct common_type<T1, T2, T...>: common_type<typename common_type<T1, T2>::type, T...>
{
};

#endif // !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES)

#else

template<
    class T1 = void, class T2 = void, class T3 = void,
    class T4 = void, class T5 = void, class T6 = void,
    class T7 = void, class T8 = void, class T9 = void
>
struct common_type: common_type<typename common_type<T1, T2>::type, T3, T4, T5, T6, T7, T8, T9>
{
};

#endif // !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES)

// one argument

template<class T> struct common_type<T>: mwboost::decay<T>
{
   BOOST_STATIC_ASSERT_MSG(::mwboost::is_complete<T>::value || ::mwboost::is_void<T>::value || ::mwboost::is_array<T>::value, "Arguments to common_type must both be complete types");
};

// two arguments

namespace type_traits_detail
{

// binary common_type

#if !defined(BOOST_NO_CXX11_DECLTYPE)

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES) && !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES)
    
#if !defined(BOOST_MSVC) || BOOST_MSVC > 1800

// internal compiler error on msvc-12.0

template<class T1, class T2> using builtin_common_type = typename mwboost::decay<decltype( mwboost::declval<bool>()? mwboost::declval<T1>(): mwboost::declval<T2>() )>::type;

template<class T1, class T2> struct common_type_impl: mp_defer<builtin_common_type, T1, T2>
{
};

#else

template<class T1, class T2> using builtin_common_type = decltype( mwboost::declval<bool>()? mwboost::declval<T1>(): mwboost::declval<T2>() );

template<class T1, class T2> struct common_type_impl_2: mp_defer<builtin_common_type, T1, T2>
{
};

template<class T1, class T2> using decay_common_type = typename mwboost::decay<typename common_type_impl_2<T1, T2>::type>::type;

template<class T1, class T2> struct common_type_impl: mp_defer<decay_common_type, T1, T2>
{
};

#endif // !defined(BOOST_MSVC) || BOOST_MSVC > 1800

#else

template<class T1, class T2> struct common_type_impl: mwboost::decay<decltype( mwboost::declval<bool>()? mwboost::declval<T1>(): mwboost::declval<T2>() )>
{
};

#endif // #if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES) && !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES)

#endif // #if !defined(BOOST_NO_CXX11_DECLTYPE)

// decay helper

template<class T1, class T2, class T1d = typename mwboost::decay<T1>::type, class T2d = typename mwboost::decay<T2>::type> struct common_type_decay_helper: mwboost::common_type<T1d, T2d>
{
};

template<class T1, class T2> struct common_type_decay_helper<T1, T2, T1, T2>: common_type_impl<T1, T2>
{
};

} // type_traits_detail

template<class T1, class T2> struct common_type<T1, T2>: type_traits_detail::common_type_decay_helper<T1, T2>
{
   BOOST_STATIC_ASSERT_MSG(::mwboost::is_complete<T1>::value || ::mwboost::is_void<T1>::value || ::mwboost::is_array<T1>::value, "Arguments to common_type must both be complete types");
   BOOST_STATIC_ASSERT_MSG(::mwboost::is_complete<T2>::value || ::mwboost::is_void<T2>::value || ::mwboost::is_array<T2>::value, "Arguments to common_type must both be complete types");
};

} // namespace mwboost

#endif // #ifndef BOOST_TYPE_TRAITS_COMMON_TYPE_HPP_INCLUDED

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
