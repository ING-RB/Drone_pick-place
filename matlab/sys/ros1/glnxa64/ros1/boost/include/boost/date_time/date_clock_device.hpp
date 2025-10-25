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

#ifndef DATE_CLOCK_DEVICE_HPP___
#define DATE_CLOCK_DEVICE_HPP___

/* Copyright (c) 2002,2003,2005 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

#include "boost/date_time/c_time.hpp"


namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace date_time {

  //! A clock providing day level services based on C time_t capabilities
  /*! This clock uses Posix interfaces as its implementation and hence
   *  uses the timezone settings of the operating system.  Incorrect
   *  user settings will result in incorrect results for the calls
   *  to local_day.
   */
  template<class date_type> 
  class day_clock
  {
  public:
    typedef typename date_type::ymd_type ymd_type;
    //! Get the local day as a date type
    static date_type local_day() 
    {
      return date_type(local_day_ymd());
    }
    //! Get the local day as a ymd_type
    static typename date_type::ymd_type local_day_ymd() 
    {
      ::std::tm result;
      ::std::tm* curr = get_local_time(result);
      return ymd_type(static_cast<unsigned short>(curr->tm_year + 1900),
                      static_cast<unsigned short>(curr->tm_mon + 1),
                      static_cast<unsigned short>(curr->tm_mday));
    }
    //! Get the current day in universal date as a ymd_type
    static typename date_type::ymd_type universal_day_ymd() 
    {
      ::std::tm result;
      ::std::tm* curr = get_universal_time(result);
      return ymd_type(static_cast<unsigned short>(curr->tm_year + 1900),
                      static_cast<unsigned short>(curr->tm_mon + 1),
                      static_cast<unsigned short>(curr->tm_mday));
    }
    //! Get the UTC day as a date type
    static date_type universal_day() 
    {
      return date_type(universal_day_ymd());
    }

  private:
    static ::std::tm* get_local_time(std::tm& result) 
    {
      ::std::time_t t;
      ::std::time(&t);
      return c_time::localtime(&t, &result);
    }
    static ::std::tm* get_universal_time(std::tm& result) 
    {
      ::std::time_t t;
      ::std::time(&t);
      return c_time::gmtime(&t, &result);
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
