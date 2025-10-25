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

/* Copyright (c) 2002,2003 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland 
 */
#ifndef POSIX_TIME_TYPES_HPP___
#define POSIX_TIME_TYPES_HPP___

#include "boost/date_time/time_clock.hpp"
#include "boost/date_time/microsec_time_clock.hpp"
#include "boost/date_time/posix_time/ptime.hpp"
#if defined(BOOST_DATE_TIME_OPTIONAL_GREGORIAN_TYPES)
#include "boost/date_time/posix_time/date_duration_operators.hpp"
#endif
#include "boost/date_time/posix_time/posix_time_duration.hpp"
#include "boost/date_time/posix_time/posix_time_system.hpp"
#include "boost/date_time/posix_time/time_period.hpp"
#include "boost/date_time/time_iterator.hpp"
#include "boost/date_time/dst_rules.hpp"

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

//!Defines a non-adjusted time system with nano-second resolution and stable calculation properties
namespace posix_time {

  //! Iterator over a defined time duration
  /*! \ingroup time_basics
   */
  typedef date_time::time_itr<ptime> time_iterator;
  //! A time clock that has a resolution of one second
  /*! \ingroup time_basics
   */
  typedef date_time::second_clock<ptime> second_clock;

#ifdef BOOST_DATE_TIME_HAS_HIGH_PRECISION_CLOCK
  //! A time clock that has a resolution of one microsecond
  /*! \ingroup time_basics
   */
  typedef date_time::microsec_clock<ptime> microsec_clock;
#endif

  //! Define a dst null dst rule for the posix_time system
  typedef date_time::null_dst_rules<ptime::date_type, time_duration> no_dst;
  //! Define US dst rule calculator for the posix_time system
  typedef date_time::us_dst_rules<ptime::date_type, time_duration> us_dst;


} } //namespace posix_time




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
