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

#ifndef POSIX_TIME_DURATION_HPP___
#define POSIX_TIME_DURATION_HPP___

/* Copyright (c) 2002,2003, 2020 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland
 * $Date$
 */

#include <boost/core/enable_if.hpp>
#include <boost/date_time/compiler_config.hpp>
#include <boost/date_time/posix_time/posix_time_config.hpp>
#include <boost/numeric/conversion/cast.hpp>
#include <boost/type_traits/is_integral.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace posix_time {

  //! Allows expression of durations as an hour count
  //! The argument must be an integral type
  /*! \ingroup time_basics
   */
  class BOOST_SYMBOL_VISIBLE hours : public time_duration
  {
  public:
      template <typename T>
      BOOST_CXX14_CONSTEXPR explicit hours(T const& h,
          typename mwboost::enable_if<mwboost::is_integral<T>, void>::type* = BOOST_DATE_TIME_NULLPTR) :
      time_duration(numeric_cast<hour_type>(h), 0, 0)
    {}
  };

  //! Allows expression of durations as a minute count
  //! The argument must be an integral type
  /*! \ingroup time_basics
   */
  class BOOST_SYMBOL_VISIBLE minutes : public time_duration
  {
  public:
      template <typename T>
      BOOST_CXX14_CONSTEXPR explicit minutes(T const& m,
          typename mwboost::enable_if<mwboost::is_integral<T>, void>::type* = BOOST_DATE_TIME_NULLPTR) :
      time_duration(0, numeric_cast<min_type>(m),0)
    {}
  };

  //! Allows expression of durations as a seconds count
  //! The argument must be an integral type
  /*! \ingroup time_basics
   */
  class BOOST_SYMBOL_VISIBLE seconds : public time_duration
  {
  public:
      template <typename T>
      BOOST_CXX14_CONSTEXPR explicit seconds(T const& s,
          typename mwboost::enable_if<mwboost::is_integral<T>, void>::type* = BOOST_DATE_TIME_NULLPTR) :
      time_duration(0,0, numeric_cast<sec_type>(s))
    {}
  };


  //! Allows expression of durations as milli seconds
  /*! \ingroup time_basics
   */
  typedef date_time::subsecond_duration<time_duration,1000> millisec;
  typedef date_time::subsecond_duration<time_duration,1000> milliseconds;

  //! Allows expression of durations as micro seconds
  /*! \ingroup time_basics
   */
  typedef date_time::subsecond_duration<time_duration,1000000> microsec;
  typedef date_time::subsecond_duration<time_duration,1000000> microseconds;

  //This is probably not needed anymore...
#if defined(BOOST_DATE_TIME_HAS_NANOSECONDS)

  //! Allows expression of durations as nano seconds
  /*! \ingroup time_basics
   */
  typedef date_time::subsecond_duration<time_duration,1000000000> nanosec;
  typedef date_time::subsecond_duration<time_duration,1000000000> nanoseconds;

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
