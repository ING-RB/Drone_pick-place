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

#ifndef _GREGORIAN_TYPES_HPP__
#define _GREGORIAN_TYPES_HPP__

/* Copyright (c) 2002,2003 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

/*! @file gregorian_types.hpp
  Single file header that defines most of the types for the gregorian 
  date-time system.
*/

#include "boost/date_time/date.hpp"
#include "boost/date_time/period.hpp"
#include "boost/date_time/gregorian/greg_calendar.hpp"
#include "boost/date_time/gregorian/greg_duration.hpp"
#if defined(BOOST_DATE_TIME_OPTIONAL_GREGORIAN_TYPES)
#include "boost/date_time/gregorian/greg_duration_types.hpp"
#endif
#include "boost/date_time/gregorian/greg_date.hpp"
#include "boost/date_time/date_generators.hpp"
#include "boost/date_time/date_clock_device.hpp"
#include "boost/date_time/date_iterator.hpp"
#include "boost/date_time/adjust_functors.hpp"

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

//! Gregorian date system based on date_time components
/*! This date system defines a full complement of types including
 *  a date, date_duration, date_period, day_clock, and a
 *  day_iterator.
 */
namespace gregorian {
  //! Date periods for the gregorian system
  /*!\ingroup date_basics
   */
  typedef date_time::period<date, date_duration> date_period;  

  //! A unifying date_generator base type
  /*! A unifying date_generator base type for: 
   * partial_date, nth_day_of_the_week_in_month,
   * first_day_of_the_week_in_month, and last_day_of_the_week_in_month
   */
  typedef date_time::year_based_generator<date> year_based_generator;

  //! A date generation object type
  typedef date_time::partial_date<date> partial_date;

  typedef date_time::nth_kday_of_month<date> nth_kday_of_month;
  typedef nth_kday_of_month nth_day_of_the_week_in_month;

  typedef date_time::first_kday_of_month<date> first_kday_of_month;
  typedef first_kday_of_month first_day_of_the_week_in_month;

  typedef date_time::last_kday_of_month<date> last_kday_of_month;
  typedef last_kday_of_month last_day_of_the_week_in_month;

  typedef date_time::first_kday_after<date> first_kday_after;
  typedef first_kday_after first_day_of_the_week_after;

  typedef date_time::first_kday_before<date> first_kday_before;
  typedef first_kday_before first_day_of_the_week_before;

  //! A clock to get the current day from the local computer
  /*!\ingroup date_basics
   */
  typedef date_time::day_clock<date> day_clock;

  //! Base date_iterator type for gregorian types.
  /*!\ingroup date_basics
   */
  typedef date_time::date_itr_base<date> date_iterator;

  //! A day level iterator
  /*!\ingroup date_basics
   */
  typedef date_time::date_itr<date_time::day_functor<date>,
                              date> day_iterator;
  //! A week level iterator
  /*!\ingroup date_basics
   */
  typedef date_time::date_itr<date_time::week_functor<date>,
                              date> week_iterator;
  //! A month level iterator
  /*!\ingroup date_basics
   */
  typedef date_time::date_itr<date_time::month_functor<date>,
                              date> month_iterator;
  //! A year level iterator
  /*!\ingroup date_basics
   */
  typedef date_time::date_itr<date_time::year_functor<date>,
                              date> year_iterator;

  // bring in these date_generator functions from date_time namespace
  using date_time::days_until_weekday;
  using date_time::days_before_weekday;
  using date_time::next_weekday;
  using date_time::previous_weekday;

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
