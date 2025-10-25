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

#ifndef DATE_TIME_TIME_CLOCK_HPP___
#define DATE_TIME_TIME_CLOCK_HPP___

/* Copyright (c) 2002,2003,2005 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

/*! @file time_clock.hpp
  This file contains the interface for clock devices.
*/

#include "boost/date_time/c_time.hpp"
#include "boost/shared_ptr.hpp"

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace date_time {


  //! A clock providing time level services based on C time_t capabilities
  /*! This clock provides resolution to the 1 second level
   */
  template<class time_type>
  class second_clock
  {
  public:
    typedef typename time_type::date_type date_type;
    typedef typename time_type::time_duration_type time_duration_type;

    static time_type local_time()
    {
      ::std::time_t t;
      ::std::time(&t);
      ::std::tm curr, *curr_ptr;
      //curr_ptr = ::std::localtime(&t);
      curr_ptr = c_time::localtime(&t, &curr);
      return create_time(curr_ptr);
    }


    //! Get the current day in universal date as a ymd_type
    static time_type universal_time()
    {

      ::std::time_t t;
      ::std::time(&t);
      ::std::tm curr, *curr_ptr;
      //curr_ptr = ::std::gmtime(&t);
      curr_ptr = c_time::gmtime(&t, &curr);
      return create_time(curr_ptr);
    }

    template<class time_zone_type>
    static time_type local_time(mwboost::shared_ptr<time_zone_type> tz_ptr)
    {
      typedef typename time_type::utc_time_type utc_time_type;
      utc_time_type utc_time = second_clock<utc_time_type>::universal_time();
      return time_type(utc_time, tz_ptr);
    }


  private:
    static time_type create_time(::std::tm* current)
    {
      date_type d(static_cast<unsigned short>(current->tm_year + 1900),
                  static_cast<unsigned short>(current->tm_mon + 1),
                  static_cast<unsigned short>(current->tm_mday));
      time_duration_type td(current->tm_hour,
                            current->tm_min,
                            current->tm_sec);
      return time_type(d,td);
    }

  };


} } //namespace date_time


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
