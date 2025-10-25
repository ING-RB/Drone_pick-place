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

#ifndef _GREGORIAN__CONVERSION_HPP___
#define _GREGORIAN__CONVERSION_HPP___

/* Copyright (c) 2004-2005 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

#include <cstring>
#include <string>
#include <stdexcept>
#include <boost/throw_exception.hpp>
#include <boost/date_time/c_time.hpp>
#include <boost/date_time/special_defs.hpp>
#include <boost/date_time/gregorian/gregorian_types.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

namespace gregorian {

  //! Converts a date to a tm struct. Throws out_of_range exception if date is a special value
  inline
  std::tm to_tm(const date& d)
  {
    if (d.is_special())
    {
        std::string s = "tm unable to handle ";
        switch (d.as_special())
        {
        case date_time::not_a_date_time:
            s += "not-a-date-time value"; break;
        case date_time::neg_infin:
            s += "-infinity date value"; break;
        case date_time::pos_infin:
            s += "+infinity date value"; break;
        default:
            s += "a special date value"; break;
        }
        mwboost::throw_exception(std::out_of_range(s));
    }

    std::tm datetm;
    std::memset(&datetm, 0, sizeof(datetm));
    mwboost::gregorian::date::ymd_type ymd = d.year_month_day();
    datetm.tm_year = ymd.year - 1900;
    datetm.tm_mon = ymd.month - 1;
    datetm.tm_mday = ymd.day;
    datetm.tm_wday = d.day_of_week();
    datetm.tm_yday = d.day_of_year() - 1;
    datetm.tm_isdst = -1; // negative because not enough info to set tm_isdst
    return datetm;
  }

  //! Converts a tm structure into a date dropping the any time values.
  inline
  date date_from_tm(const std::tm& datetm)
  {
    return date(static_cast<unsigned short>(datetm.tm_year+1900),
                static_cast<unsigned short>(datetm.tm_mon+1),
                static_cast<unsigned short>(datetm.tm_mday));
  }

} } //namespace mwboost::gregorian

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
