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

#ifndef BOOST_BIND_STD_PLACEHOLDERS_HPP_INCLUDED
#define BOOST_BIND_STD_PLACEHOLDERS_HPP_INCLUDED

// MS compatible compilers support #pragma once

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

// Copyright 2021 Peter Dimov
// Distributed under the Boost Software License, Version 1.0.
// https://www.boost.org/LICENSE_1_0.txt

#include <boost/is_placeholder.hpp>
#include <boost/config.hpp>

#if !defined(BOOST_NO_CXX11_HDR_FUNCTIONAL) && !defined(BOOST_NO_CXX11_DECLTYPE) && !defined(BOOST_NO_CXX11_HDR_TYPE_TRAITS)

#include <functional>
#include <type_traits>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_1)>::type > { enum _vt { value = 1 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_2)>::type > { enum _vt { value = 2 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_3)>::type > { enum _vt { value = 3 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_4)>::type > { enum _vt { value = 4 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_5)>::type > { enum _vt { value = 5 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_6)>::type > { enum _vt { value = 6 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_7)>::type > { enum _vt { value = 7 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_8)>::type > { enum _vt { value = 8 }; };
template<> struct is_placeholder< typename std::decay<decltype(std::placeholders::_9)>::type > { enum _vt { value = 9 }; };

} // namespace mwboost

#endif

#endif // #ifndef BOOST_BIND_STD_PLACEHOLDERS_HPP_INCLUDED

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
