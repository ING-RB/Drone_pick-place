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


// (C) Copyright Steve Cleary, Beman Dawes, Howard Hinnant & John Maddock 2000.
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.

#ifndef BOOST_TT_IS_EMPTY_HPP_INCLUDED
#define BOOST_TT_IS_EMPTY_HPP_INCLUDED

#include <boost/type_traits/is_convertible.hpp>
#include <boost/type_traits/detail/config.hpp>
#include <boost/type_traits/intrinsics.hpp>

#include <boost/type_traits/remove_cv.hpp>
#include <boost/type_traits/is_class.hpp>
#include <boost/type_traits/add_reference.hpp>

#ifndef BOOST_INTERNAL_IS_EMPTY
#define BOOST_INTERNAL_IS_EMPTY(T) false
#else
#define BOOST_INTERNAL_IS_EMPTY(T) BOOST_IS_EMPTY(T)
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

namespace detail {


#ifdef BOOST_MSVC
#pragma warning(push)
#pragma warning(disable:4624) // destructor could not be generated
#endif

template <typename T>
struct empty_helper_t1 : public T
{
    empty_helper_t1();  // hh compiler bug workaround
    int i[256];
private:
   // suppress compiler warnings:
   empty_helper_t1(const empty_helper_t1&);
   empty_helper_t1& operator=(const empty_helper_t1&);
};

#ifdef BOOST_MSVC
#pragma warning(pop)
#endif

struct empty_helper_t2 { int i[256]; };

#if !BOOST_WORKAROUND(BOOST_BORLANDC, < 0x600)

template <typename T, bool is_a_class = false>
struct empty_helper
{
    BOOST_STATIC_CONSTANT(bool, value = false);
};

template <typename T>
struct empty_helper<T, true>
{
    BOOST_STATIC_CONSTANT(
        bool, value = (sizeof(empty_helper_t1<T>) == sizeof(empty_helper_t2))
        );
};

template <typename T>
struct is_empty_impl
{
    typedef typename remove_cv<T>::type cvt;
    BOOST_STATIC_CONSTANT(
        bool, 
        value = ( ::mwboost::detail::empty_helper<cvt,::mwboost::is_class<T>::value>::value || BOOST_INTERNAL_IS_EMPTY(cvt)));
};

#else // BOOST_BORLANDC

template <typename T, bool is_a_class, bool convertible_to_int>
struct empty_helper
{
    BOOST_STATIC_CONSTANT(bool, value = false);
};

template <typename T>
struct empty_helper<T, true, false>
{
    BOOST_STATIC_CONSTANT(bool, value = (
        sizeof(empty_helper_t1<T>) == sizeof(empty_helper_t2)
        ));
};

template <typename T>
struct is_empty_impl
{
   typedef typename remove_cv<T>::type cvt;
   typedef typename add_reference<T>::type r_type;

   BOOST_STATIC_CONSTANT(
       bool, value = (
              ::mwboost::detail::empty_helper<
                  cvt
                , ::mwboost::is_class<T>::value
                , ::mwboost::is_convertible< r_type,int>::value
              >::value || BOOST_INTERNAL_IS_EMPTY(cvt)));
};

#endif // BOOST_BORLANDC

} // namespace detail

template <class T> struct is_empty : integral_constant<bool, ::mwboost::detail::is_empty_impl<T>::value> {};

} // namespace mwboost

#undef BOOST_INTERNAL_IS_EMPTY

#endif // BOOST_TT_IS_EMPTY_HPP_INCLUDED


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
