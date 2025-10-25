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
//  (C) Copyright Eric Friedman 2002-2003.
//  (C) Copyright Antony Polukhin 2013.
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.

#ifndef BOOST_TT_IS_NOTHROW_MOVE_CONSTRUCTIBLE_HPP_INCLUDED
#define BOOST_TT_IS_NOTHROW_MOVE_CONSTRUCTIBLE_HPP_INCLUDED

#include <cstddef> // size_t
#include <boost/config.hpp>
#include <boost/type_traits/intrinsics.hpp>
#include <boost/type_traits/integral_constant.hpp>
#include <boost/detail/workaround.hpp>
#include <boost/type_traits/is_complete.hpp>
#include <boost/static_assert.hpp>

#ifdef BOOST_IS_NOTHROW_MOVE_CONSTRUCT

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template <class T>
struct is_nothrow_move_constructible : public integral_constant<bool, BOOST_IS_NOTHROW_MOVE_CONSTRUCT(T)>
{
   BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_nothrow_move_constructible must be complete types");
};

template <class T> struct is_nothrow_move_constructible<volatile T> : public ::mwboost::false_type {};
template <class T> struct is_nothrow_move_constructible<const volatile T> : public ::mwboost::false_type{};

#elif !defined(BOOST_NO_CXX11_NOEXCEPT) && !defined(BOOST_NO_SFINAE_EXPR) && !BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40700)

#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/enable_if.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{ namespace detail{

template <class T, class Enable = void>
struct false_or_cpp11_noexcept_move_constructible: public ::mwboost::false_type {};

template <class T>
struct false_or_cpp11_noexcept_move_constructible <
        T,
        typename ::mwboost::enable_if_<sizeof(T) && BOOST_NOEXCEPT_EXPR(T(::mwboost::declval<T>()))>::type
    > : public ::mwboost::integral_constant<bool, BOOST_NOEXCEPT_EXPR(T(::mwboost::declval<T>()))>
{};

}

template <class T> struct is_nothrow_move_constructible
   : public integral_constant<bool, ::mwboost::detail::false_or_cpp11_noexcept_move_constructible<T>::value>
{
   BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_nothrow_move_constructible must be complete types");
};

template <class T> struct is_nothrow_move_constructible<volatile T> : public ::mwboost::false_type {};
template <class T> struct is_nothrow_move_constructible<const volatile T> : public ::mwboost::false_type{};
template <class T, std::size_t N> struct is_nothrow_move_constructible<T[N]> : public ::mwboost::false_type{};
template <class T> struct is_nothrow_move_constructible<T[]> : public ::mwboost::false_type{};

#else

#include <boost/type_traits/has_trivial_move_constructor.hpp>
#include <boost/type_traits/has_nothrow_copy.hpp>
#include <boost/type_traits/is_array.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost{

template <class T>
struct is_nothrow_move_constructible
   : public integral_constant<bool,
   (::mwboost::has_trivial_move_constructor<T>::value || ::mwboost::has_nothrow_copy<T>::value) && !::mwboost::is_array<T>::value>
{
   BOOST_STATIC_ASSERT_MSG(mwboost::is_complete<T>::value, "Arguments to is_nothrow_move_constructible must be complete types");
};

#endif

template <> struct is_nothrow_move_constructible<void> : false_type{};
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
template <> struct is_nothrow_move_constructible<void const> : false_type{};
template <> struct is_nothrow_move_constructible<void volatile> : false_type{};
template <> struct is_nothrow_move_constructible<void const volatile> : false_type{};
#endif
// References are always trivially constructible, even if the thing they reference is not:
template <class T> struct is_nothrow_move_constructible<T&> : public ::mwboost::true_type{};
#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
template <class T> struct is_nothrow_move_constructible<T&&> : public ::mwboost::true_type{};
#endif

} // namespace mwboost

#endif // BOOST_TT_IS_NOTHROW_MOVE_CONSTRUCTIBLE_HPP_INCLUDED

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
