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

#ifndef POSIX_TIME_CONFIG_HPP___
#define POSIX_TIME_CONFIG_HPP___

/* Copyright (c) 2002,2003,2005,2020 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

#include <cstdlib> //for MCW 7.2 std::abs(long long)
#include <boost/limits.hpp>
#include <boost/cstdint.hpp>
#include <boost/config/no_tr1/cmath.hpp>
#include <boost/date_time/time_duration.hpp>
#include <boost/date_time/time_resolution_traits.hpp>
#include <boost/date_time/gregorian/gregorian_types.hpp>
#include <boost/date_time/wrapping_int.hpp>
#include <boost/date_time/compiler_config.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace posix_time {


#ifdef BOOST_DATE_TIME_POSIX_TIME_STD_CONFIG
  // set up conditional test compilations
#define BOOST_DATE_TIME_HAS_NANOSECONDS
  typedef date_time::time_resolution_traits<mwboost::date_time::time_resolution_traits_adapted64_impl, mwboost::date_time::nano,
    1000000000, 9 > time_res_traits;
#else
  // set up conditional test compilations
#undef  BOOST_DATE_TIME_HAS_NANOSECONDS
  typedef date_time::time_resolution_traits<
    mwboost::date_time::time_resolution_traits_adapted64_impl, mwboost::date_time::micro,
                                            1000000, 6 > time_res_traits;

#endif


  //! Base time duration type
  /*! \ingroup time_basics
   */
  class BOOST_SYMBOL_VISIBLE time_duration :
    public date_time::time_duration<time_duration, time_res_traits>
  {
  public:
    typedef time_res_traits rep_type;
    typedef time_res_traits::day_type day_type;
    typedef time_res_traits::hour_type hour_type;
    typedef time_res_traits::min_type min_type;
    typedef time_res_traits::sec_type sec_type;
    typedef time_res_traits::fractional_seconds_type fractional_seconds_type;
    typedef time_res_traits::tick_type tick_type;
    typedef time_res_traits::impl_type impl_type;
    BOOST_CXX14_CONSTEXPR time_duration(hour_type hour,
                                        min_type min,
                                        sec_type sec,
                                        fractional_seconds_type fs=0) :
      date_time::time_duration<time_duration, time_res_traits>(hour,min,sec,fs)
    {}
   BOOST_CXX14_CONSTEXPR time_duration() :
      date_time::time_duration<time_duration, time_res_traits>(0,0,0)
    {}
    //! Construct from special_values
    BOOST_CXX14_CONSTEXPR time_duration(mwboost::date_time::special_values sv) :
      date_time::time_duration<time_duration, time_res_traits>(sv)
    {}
    //Give duration access to ticks constructor -- hide from users
    friend class date_time::time_duration<time_duration, time_res_traits>;
  protected:
    BOOST_CXX14_CONSTEXPR explicit time_duration(impl_type tick_count) :
      date_time::time_duration<time_duration, time_res_traits>(tick_count)
    {}
  };

#ifdef BOOST_DATE_TIME_POSIX_TIME_STD_CONFIG

  //! Simple implementation for the time rep
  struct simple_time_rep
  {
    typedef gregorian::date      date_type;
    typedef time_duration        time_duration_type;
    BOOST_CXX14_CONSTEXPR simple_time_rep(date_type d, time_duration_type tod) :
      day(d),
      time_of_day(tod)
    {
      // make sure we have sane values for date & time
      if(!day.is_special() && !time_of_day.is_special()){
        if(time_of_day >= time_duration_type(24,0,0)) {
          while(time_of_day >= time_duration_type(24,0,0)) {
            day += date_type::duration_type(1);
            time_of_day -= time_duration_type(24,0,0);
          }
        }
        else if(time_of_day.is_negative()) {
          while(time_of_day.is_negative()) {
            day -= date_type::duration_type(1);
            time_of_day += time_duration_type(24,0,0);
          }
        }
      }
    }
    date_type day;
    time_duration_type time_of_day;
    BOOST_CXX14_CONSTEXPR bool is_special()const
    {
      return(is_pos_infinity() || is_neg_infinity() || is_not_a_date_time());
    }
    BOOST_CXX14_CONSTEXPR bool is_pos_infinity()const
    {
      return(day.is_pos_infinity() || time_of_day.is_pos_infinity());
    }
    BOOST_CXX14_CONSTEXPR bool is_neg_infinity()const
    {
      return(day.is_neg_infinity() || time_of_day.is_neg_infinity());
    }
    BOOST_CXX14_CONSTEXPR bool is_not_a_date_time()const
    {
      return(day.is_not_a_date() || time_of_day.is_not_a_date_time());
    }
  };

  class BOOST_SYMBOL_VISIBLE posix_time_system_config
  {
   public:
    typedef simple_time_rep time_rep_type;
    typedef gregorian::date date_type;
    typedef gregorian::date_duration date_duration_type;
    typedef time_duration time_duration_type;
    typedef time_res_traits::tick_type int_type;
    typedef time_res_traits resolution_traits;
#if (defined(BOOST_DATE_TIME_NO_MEMBER_INIT)) //help bad compilers
#else
    BOOST_STATIC_CONSTANT(mwboost::int64_t, tick_per_second = 1000000000);
#endif
  };

#else

  class millisec_posix_time_system_config
  {
   public:
    typedef mwboost::int64_t time_rep_type;
    //typedef time_res_traits::tick_type time_rep_type;
    typedef gregorian::date date_type;
    typedef gregorian::date_duration date_duration_type;
    typedef time_duration time_duration_type;
    typedef time_res_traits::tick_type int_type;
    typedef time_res_traits::impl_type impl_type;
    typedef time_res_traits resolution_traits;
#if (defined(BOOST_DATE_TIME_NO_MEMBER_INIT)) //help bad compilers
#else
    BOOST_STATIC_CONSTANT(mwboost::int64_t, tick_per_second = 1000000);
#endif
  };

#endif

} }//namespace posix_time


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
