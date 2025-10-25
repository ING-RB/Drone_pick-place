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

//  (c) Copyright Fernando Luis Cacciola Carballal 2000-2004
//  Use, modification, and distribution is subject to the Boost Software
//  License, Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

//  See library home page at http://www.boost.org/libs/numeric/conversion
//
// Contact the author at: fernando_cacciola@hotmail.com
//
//
//  Revision History
//
//    19 Nov 2001 Syntatic changes as suggested by Darin Adler (Fernando Cacciola)
//    08 Nov 2001 Fixes to accommodate MSVC (Fernando Cacciola)
//    04 Nov 2001 Fixes to accommodate gcc2.92 (Fernando Cacciola)
//    30 Oct 2001 Some fixes suggested by Daryle Walker (Fernando Cacciola)
//    25 Oct 2001 Initial boostification (Fernando Cacciola)
//    23 Jan 2004 Inital add to cvs (post review)s
//    22 Jun 2011 Added support for specializing cast policies via numeric_cast_traits (Brandon Kohn).
//
#ifndef BOOST_NUMERIC_CONVERSION_CAST_25OCT2001_HPP
#define BOOST_NUMERIC_CONVERSION_CAST_25OCT2001_HPP

#include <boost/detail/workaround.hpp>

#if BOOST_WORKAROUND(BOOST_BORLANDC, BOOST_TESTED_AT(0x582))

#  include<boost/numeric/conversion/detail/old_numeric_cast.hpp>

#else

#include <boost/type.hpp>
#include <boost/numeric/conversion/converter.hpp>
#include <boost/numeric/conversion/numeric_cast_traits.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
    template <typename Target, typename Source> 
    inline Target numeric_cast( Source arg )
    {
        typedef numeric::conversion_traits<Target, Source>   conv_traits;
        typedef numeric::numeric_cast_traits<Target, Source> cast_traits;
        typedef mwboost::numeric::converter
            <
                Target,
                Source, 
                conv_traits,
                typename cast_traits::overflow_policy, 
                typename cast_traits::rounding_policy, 
                mwboost::numeric::raw_converter< conv_traits >,
                typename cast_traits::range_checking_policy
            > converter;
        return converter::convert(arg);
    }
    
    using numeric::bad_numeric_cast;
} // namespace mwboost

#endif

#endif

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
