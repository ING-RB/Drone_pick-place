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

#ifndef GREG_DURATION_TYPES_HPP___
#define GREG_DURATION_TYPES_HPP___

/* Copyright (c) 2004 CrystalClear Software, Inc.
 * Subject to Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */


#include <boost/date_time/compiler_config.hpp>
#include <boost/date_time/gregorian/greg_date.hpp>
#include <boost/date_time/int_adapter.hpp>
#include <boost/date_time/adjust_functors.hpp>
#include <boost/date_time/date_duration_types.hpp>
#include <boost/date_time/gregorian/greg_duration.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace gregorian {

  //! config struct for additional duration types (ie months_duration<> & years_duration<>)
  struct BOOST_SYMBOL_VISIBLE greg_durations_config {
    typedef date date_type;
    typedef date_time::int_adapter<int> int_rep;
    typedef date_time::month_functor<date_type> month_adjustor_type; 
  };

  typedef date_time::months_duration<greg_durations_config> months;
  typedef date_time::years_duration<greg_durations_config> years;

  class BOOST_SYMBOL_VISIBLE weeks_duration : public date_duration {
  public:
    BOOST_CXX14_CONSTEXPR weeks_duration(duration_rep w) 
      : date_duration(w * 7) {}
    BOOST_CXX14_CONSTEXPR weeks_duration(date_time::special_values sv) 
      : date_duration(sv) {}
  };

  typedef weeks_duration weeks;

}} // namespace mwboost::gregorian

#endif // GREG_DURATION_TYPES_HPP___

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
