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

#ifndef BOOST_BIND_PLACEHOLDERS_HPP_INCLUDED
#define BOOST_BIND_PLACEHOLDERS_HPP_INCLUDED

// MS compatible compilers support #pragma once

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

//
//  bind/placeholders.hpp - _N definitions
//
//  Copyright (c) 2002 Peter Dimov and Multi Media Ltd.
//  Copyright 2015 Peter Dimov
//
//  Distributed under the Boost Software License, Version 1.0.
//  See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt
//
//  See http://www.boost.org/libs/bind/bind.html for documentation.
//

#include <boost/bind/arg.hpp>
#include <boost/config.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

namespace placeholders
{

#if defined(BOOST_BORLANDC) || defined(__GNUC__) && (__GNUC__ < 4)

inline mwboost::arg<1> _1() { return mwboost::arg<1>(); }
inline mwboost::arg<2> _2() { return mwboost::arg<2>(); }
inline mwboost::arg<3> _3() { return mwboost::arg<3>(); }
inline mwboost::arg<4> _4() { return mwboost::arg<4>(); }
inline mwboost::arg<5> _5() { return mwboost::arg<5>(); }
inline mwboost::arg<6> _6() { return mwboost::arg<6>(); }
inline mwboost::arg<7> _7() { return mwboost::arg<7>(); }
inline mwboost::arg<8> _8() { return mwboost::arg<8>(); }
inline mwboost::arg<9> _9() { return mwboost::arg<9>(); }

#elif !defined(BOOST_NO_CXX17_INLINE_VARIABLES)

BOOST_INLINE_CONSTEXPR mwboost::arg<1> _1;
BOOST_INLINE_CONSTEXPR mwboost::arg<2> _2;
BOOST_INLINE_CONSTEXPR mwboost::arg<3> _3;
BOOST_INLINE_CONSTEXPR mwboost::arg<4> _4;
BOOST_INLINE_CONSTEXPR mwboost::arg<5> _5;
BOOST_INLINE_CONSTEXPR mwboost::arg<6> _6;
BOOST_INLINE_CONSTEXPR mwboost::arg<7> _7;
BOOST_INLINE_CONSTEXPR mwboost::arg<8> _8;
BOOST_INLINE_CONSTEXPR mwboost::arg<9> _9;

#else

BOOST_STATIC_CONSTEXPR mwboost::arg<1> _1;
BOOST_STATIC_CONSTEXPR mwboost::arg<2> _2;
BOOST_STATIC_CONSTEXPR mwboost::arg<3> _3;
BOOST_STATIC_CONSTEXPR mwboost::arg<4> _4;
BOOST_STATIC_CONSTEXPR mwboost::arg<5> _5;
BOOST_STATIC_CONSTEXPR mwboost::arg<6> _6;
BOOST_STATIC_CONSTEXPR mwboost::arg<7> _7;
BOOST_STATIC_CONSTEXPR mwboost::arg<8> _8;
BOOST_STATIC_CONSTEXPR mwboost::arg<9> _9;

#endif

} // namespace placeholders

} // namespace mwboost

#endif // #ifndef BOOST_BIND_PLACEHOLDERS_HPP_INCLUDED

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
