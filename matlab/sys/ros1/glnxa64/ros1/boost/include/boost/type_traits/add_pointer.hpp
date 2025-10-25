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

#ifndef BOOST_TT_ADD_POINTER_HPP_INCLUDED
#define BOOST_TT_ADD_POINTER_HPP_INCLUDED

#include <boost/type_traits/remove_reference.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#if defined(BOOST_BORLANDC) && (BOOST_BORLANDC < 0x5A0)
//
// For some reason this implementation stops Borlands compiler
// from dropping cv-qualifiers, it still fails with references
// to arrays for some reason though (shrug...) (JM 20021104)
//
template <typename T>
struct add_pointer
{
    typedef T* type;
};
template <typename T>
struct add_pointer<T&>
{
    typedef T* type;
};
template <typename T>
struct add_pointer<T&const>
{
    typedef T* type;
};
template <typename T>
struct add_pointer<T&volatile>
{
    typedef T* type;
};
template <typename T>
struct add_pointer<T&const volatile>
{
    typedef T* type;
};

#else

template <typename T>
struct add_pointer
{
    typedef typename remove_reference<T>::type no_ref_type;
    typedef no_ref_type* type;
};

#endif

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES)

   template <class T> using add_pointer_t = typename add_pointer<T>::type;

#endif

} // namespace mwboost

#endif // BOOST_TT_ADD_POINTER_HPP_INCLUDED

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
