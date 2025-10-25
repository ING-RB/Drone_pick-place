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

#ifndef GREGORIAN_GREGORIAN_CALENDAR_HPP__
#define GREGORIAN_GREGORIAN_CALENDAR_HPP__

/* Copyright (c) 2002,2003 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland
 * $Date$
 */

#include <boost/cstdint.hpp>
#include <boost/date_time/compiler_config.hpp>
#include <boost/date_time/gregorian/greg_weekday.hpp>
#include <boost/date_time/gregorian/greg_day_of_year.hpp>
#include <boost/date_time/gregorian_calendar.hpp>
#include <boost/date_time/gregorian/greg_ymd.hpp>
#include <boost/date_time/int_adapter.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace gregorian {

  //!An internal date representation that includes infinities, not a date
  typedef date_time::int_adapter<uint32_t> fancy_date_rep;

  //! Gregorian calendar for this implementation, hard work in the base
  class BOOST_SYMBOL_VISIBLE gregorian_calendar :
    public date_time::gregorian_calendar_base<greg_year_month_day, fancy_date_rep::int_type> {
  public:
    //! Type to hold a weekday (eg: Sunday, Monday,...)
    typedef greg_weekday         day_of_week_type;
    //! Counter type from 1 to 366 for gregorian dates.
    typedef greg_day_of_year_rep day_of_year_type;
    //! Internal date representation that handles infinity, not a date
    typedef fancy_date_rep       date_rep_type;
    //! Date rep implements the traits stuff as well
    typedef fancy_date_rep       date_traits_type;


  private:
  };

} } //namespace gregorian




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
