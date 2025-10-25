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

//  declval.hpp  -------------------------------------------------------------//

//  Copyright 2010 Vicente J. Botet Escriba

//  Distributed under the Boost Software License, Version 1.0.
//  See http://www.boost.org/LICENSE_1_0.txt

#ifndef BOOST_TYPE_TRAITS_DECLVAL_HPP_INCLUDED
#define BOOST_TYPE_TRAITS_DECLVAL_HPP_INCLUDED

#include <boost/config.hpp>

//----------------------------------------------------------------------------//

#include <boost/type_traits/add_rvalue_reference.hpp>

//----------------------------------------------------------------------------//
//                                                                            //
//                           C++03 implementation of                          //
//                   20.2.4 Function template declval [declval]               //
//                          Written by Vicente J. Botet Escriba               //
//                                                                            //
// 1 The library provides the function template declval to simplify the
// definition of expressions which occur as unevaluated operands.
// 2 Remarks: If this function is used, the program is ill-formed.
// 3 Remarks: The template parameter T of declval may be an incomplete type.
// [ Example:
//
// template <class To, class From>
// decltype(static_cast<To>(declval<From>())) convert(From&&);
//
// declares a function template convert which only participates in overloading
// if the type From can be explicitly converted to type To. For another example
// see class template common_type (20.9.7.6). -end example ]
//----------------------------------------------------------------------------//

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

    template <typename T>
    typename add_rvalue_reference<T>::type declval() BOOST_NOEXCEPT; // as unevaluated operand

}  // namespace mwboost

#endif  // BOOST_TYPE_TRAITS_DECLVAL_HPP_INCLUDED

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
