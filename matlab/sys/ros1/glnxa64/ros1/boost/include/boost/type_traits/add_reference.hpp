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

#ifndef BOOST_TT_ADD_REFERENCE_HPP_INCLUDED
#define BOOST_TT_ADD_REFERENCE_HPP_INCLUDED

#include <boost/detail/workaround.hpp>
#include <boost/config.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

namespace detail {

//
// We can't filter out rvalue_references at the same level as
// references or we get ambiguities from msvc:
//

template <typename T>
struct add_reference_impl
{
    typedef T& type;
};

#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
template <typename T>
struct add_reference_impl<T&&>
{
    typedef T&& type;
};
#endif

} // namespace detail

template <class T> struct add_reference
{
   typedef typename mwboost::detail::add_reference_impl<T>::type type;
};
template <class T> struct add_reference<T&>
{
   typedef T& type;
};

// these full specialisations are always required:
template <> struct add_reference<void> { typedef void type; };
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
template <> struct add_reference<const void> { typedef const void type; };
template <> struct add_reference<const volatile void> { typedef const volatile void type; };
template <> struct add_reference<volatile void> { typedef volatile void type; };
#endif

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES)

template <class T> using add_reference_t = typename add_reference<T>::type;

#endif


} // namespace mwboost

#endif // BOOST_TT_ADD_REFERENCE_HPP_INCLUDED

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
