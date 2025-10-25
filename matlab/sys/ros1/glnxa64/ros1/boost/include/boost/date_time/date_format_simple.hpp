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

#ifndef DATE_TIME_SIMPLE_FORMAT_HPP___
#define DATE_TIME_SIMPLE_FORMAT_HPP___

/* Copyright (c) 2002,2003 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

#include "boost/date_time/parse_format_base.hpp"

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace date_time {

//! Class to provide simple basic formatting rules
template<class charT>
class simple_format {
public:

  //! String used printed is date is invalid
  static const charT* not_a_date()
  {
    return "not-a-date-time";
  }
  //! String used to for positive infinity value
  static const charT* pos_infinity()
  {  
    return "+infinity";
  }
  //! String used to for positive infinity value
  static const charT* neg_infinity()
  {
    return "-infinity";
  }
  //! Describe month format
  static month_format_spec month_format()
  {
    return month_as_short_string;
  }
  static ymd_order_spec date_order()
  {
    return ymd_order_iso; //YYYY-MM-DD
  }
  //! This format uses '-' to separate date elements
  static bool has_date_sep_chars()
  {
    return true;
  }
  //! Char to sep?
  static charT year_sep_char()
  {
    return '-';
  }
  //! char between year-month
  static charT month_sep_char()
  {
    return '-';
  }
  //! Char to separate month-day
  static charT day_sep_char()
  {
    return '-';
  }
  //! char between date-hours
  static charT hour_sep_char()
  {
    return ' ';
  }
  //! char between hour and minute
  static charT minute_sep_char()
  {
    return ':';
  }
  //! char for second
  static charT second_sep_char()
  {
    return ':';
  }

};

#ifndef BOOST_NO_STD_WSTRING

//! Specialization of formmating rules for wchar_t
template<>
class simple_format<wchar_t> {
public:

  //! String used printed is date is invalid
  static const wchar_t* not_a_date()
  {
    return L"not-a-date-time";
  }
  //! String used to for positive infinity value
  static const wchar_t* pos_infinity()
  {   
    return L"+infinity";
  }
  //! String used to for positive infinity value
  static const wchar_t* neg_infinity()
  {
    return L"-infinity";
  }
  //! Describe month format
  static month_format_spec month_format()
  {
    return month_as_short_string;
  }
  static ymd_order_spec date_order()
  {
    return ymd_order_iso; //YYYY-MM-DD
  }
  //! This format uses '-' to separate date elements
  static bool has_date_sep_chars()
  {
    return true;
  }
  //! Char to sep?
  static wchar_t year_sep_char()
  {
    return '-';
  }
  //! char between year-month
  static wchar_t month_sep_char()
  {
    return '-';
  }
  //! Char to separate month-day
  static wchar_t day_sep_char()
  {
    return '-';
  }
  //! char between date-hours
  static wchar_t hour_sep_char()
  {
    return ' ';
  }
  //! char between hour and minute
  static wchar_t minute_sep_char()
  {
    return ':';
  }
  //! char for second
  static wchar_t second_sep_char()
  {
    return ':';
  }

};

#endif // BOOST_NO_STD_WSTRING
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
