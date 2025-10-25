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

//  boost/memory_order.hpp
//
//  Defines enum mwboost::memory_order per the C++0x working draft
//
//  Copyright (c) 2008, 2009 Peter Dimov
//  Copyright (c) 2018 Andrey Semashev
//
//  Distributed under the Boost Software License, Version 1.0.
//  See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_MEMORY_ORDER_HPP_INCLUDED
#define BOOST_MEMORY_ORDER_HPP_INCLUDED

#include <boost/config.hpp>

#if defined(BOOST_HAS_PRAGMA_ONCE)
# pragma once
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

//
// Enum values are chosen so that code that needs to insert
// a trailing fence for acquire semantics can use a single
// test such as:
//
// if( mo & memory_order_acquire ) { ...fence... }
//
// For leading fences one can use:
//
// if( mo & memory_order_release ) { ...fence... }
//
// Architectures such as Alpha that need a fence on consume
// can use:
//
// if( mo & ( memory_order_acquire | memory_order_consume ) ) { ...fence... }
//
// The values are also in the order of increasing "strength"
// of the fences so that success/failure orders can be checked
// efficiently in compare_exchange methods.
//

#if !defined(BOOST_NO_CXX11_SCOPED_ENUMS)

enum class memory_order : unsigned int
{
    relaxed = 0,
    consume = 1,
    acquire = 2,
    release = 4,
    acq_rel = 6, // acquire | release
    seq_cst = 14 // acq_rel | 8
};

BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST memory_order memory_order_relaxed = memory_order::relaxed;
BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST memory_order memory_order_consume = memory_order::consume;
BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST memory_order memory_order_acquire = memory_order::acquire;
BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST memory_order memory_order_release = memory_order::release;
BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST memory_order memory_order_acq_rel = memory_order::acq_rel;
BOOST_INLINE_VARIABLE BOOST_CONSTEXPR_OR_CONST memory_order memory_order_seq_cst = memory_order::seq_cst;

#undef BOOST_MEMORY_ORDER_INLINE_VARIABLE

#else // !defined(BOOST_NO_CXX11_SCOPED_ENUMS)

enum memory_order
{
    memory_order_relaxed = 0,
    memory_order_consume = 1,
    memory_order_acquire = 2,
    memory_order_release = 4,
    memory_order_acq_rel = 6, // acquire | release
    memory_order_seq_cst = 14 // acq_rel | 8
};

#endif // !defined(BOOST_NO_CXX11_SCOPED_ENUMS)

} // namespace mwboost

#endif // #ifndef BOOST_MEMORY_ORDER_HPP_INCLUDED

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
