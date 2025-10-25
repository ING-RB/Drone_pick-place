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

#ifndef LOCAL_TIME_DST_TRANSITION_DAY_RULES_HPP__
#define LOCAL_TIME_DST_TRANSITION_DAY_RULES_HPP__

/* Copyright (c) 2003-2004 CrystalClear Software, Inc.
 * Subject to the Boost Software License, Version 1.0. 
 * (See accompanying file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */


#include "boost/date_time/gregorian/gregorian_types.hpp"
#include "boost/date_time/dst_transition_generators.hpp"

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace local_time {
   
    //! Provides rule of the form starting Apr 30 ending Oct 21
    typedef date_time::dst_day_calc_rule<gregorian::date> dst_calc_rule;

    struct partial_date_rule_spec 
    {
      typedef gregorian::date date_type;
      typedef gregorian::partial_date start_rule;
      typedef gregorian::partial_date end_rule;
    };
    
    //! Provides rule of the form first Sunday in April, last Saturday in Oct
    typedef date_time::day_calc_dst_rule<partial_date_rule_spec> partial_date_dst_rule;

    struct first_last_rule_spec 
    {
      typedef gregorian::date date_type;
      typedef gregorian::first_kday_of_month start_rule;
      typedef gregorian::last_kday_of_month end_rule;
    };

    //! Provides rule of the form first Sunday in April, last Saturday in Oct
    typedef date_time::day_calc_dst_rule<first_last_rule_spec> first_last_dst_rule;

    struct last_last_rule_spec 
    {
      typedef gregorian::date date_type;
      typedef gregorian::last_kday_of_month start_rule;
      typedef gregorian::last_kday_of_month end_rule;
    };

    //! Provides rule of the form last Sunday in April, last Saturday in Oct
    typedef date_time::day_calc_dst_rule<last_last_rule_spec> last_last_dst_rule;

    struct nth_last_rule_spec
    {
      typedef gregorian::date date_type;
      typedef gregorian::nth_kday_of_month start_rule;
      typedef gregorian::last_kday_of_month end_rule;
    };

    //! Provides rule in form of [1st|2nd|3rd|4th] Sunday in April, last Sunday in Oct
    typedef date_time::day_calc_dst_rule<nth_last_rule_spec> nth_last_dst_rule;
    
    struct nth_kday_rule_spec
    {
      typedef gregorian::date date_type;
      typedef gregorian::nth_kday_of_month start_rule;
      typedef gregorian::nth_kday_of_month end_rule;
    };

    //! Provides rule in form of [1st|2nd|3rd|4th] Sunday in April/October
    typedef date_time::day_calc_dst_rule<nth_kday_rule_spec> nth_kday_dst_rule;
    //! Provides rule in form of [1st|2nd|3rd|4th] Sunday in April/October
    typedef date_time::day_calc_dst_rule<nth_kday_rule_spec> nth_day_of_the_week_in_month_dst_rule;


} }//namespace


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
