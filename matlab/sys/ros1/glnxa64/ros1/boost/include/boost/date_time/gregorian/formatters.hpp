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

#ifndef GREGORIAN_FORMATTERS_HPP___
#define GREGORIAN_FORMATTERS_HPP___

/* Copyright (c) 2002,2003 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

#include "boost/date_time/compiler_config.hpp"
#include "boost/date_time/gregorian/gregorian_types.hpp"
#if defined(BOOST_DATE_TIME_INCLUDE_LIMITED_HEADERS)
#include "boost/date_time/date_formatting_limited.hpp"
#else
#include "boost/date_time/date_formatting.hpp"
#endif
#include "boost/date_time/iso_format.hpp"
#include "boost/date_time/date_format_simple.hpp"

/* NOTE: "to_*_string" code for older compilers, ones that define 
 * BOOST_DATE_TIME_INCLUDE_LIMITED_HEADERS, is located in 
 * formatters_limited.hpp
 */

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace gregorian {

  // wrapper function for to_simple_(w)string(date)
  template<class charT>
  inline 
  std::basic_string<charT> to_simple_string_type(const date& d) {
    return date_time::date_formatter<date,date_time::simple_format<charT>,charT>::date_to_string(d);
  }
  //! To YYYY-mmm-DD string where mmm 3 char month name. Example:  2002-Jan-01
  /*!\ingroup date_format
   */
  inline std::string to_simple_string(const date& d) {
    return to_simple_string_type<char>(d);
  }


  // wrapper function for to_simple_(w)string(date_period)
  template<class charT>
  inline std::basic_string<charT> to_simple_string_type(const date_period& d) {
    typedef std::basic_string<charT> string_type;
    charT b = '[', m = '/', e=']';

    string_type d1(date_time::date_formatter<date,date_time::simple_format<charT>,charT>::date_to_string(d.begin()));
    string_type d2(date_time::date_formatter<date,date_time::simple_format<charT>,charT>::date_to_string(d.last()));
    return string_type(b + d1 + m + d2 + e);
  }
  //! Convert date period to simple string. Example: [2002-Jan-01/2002-Jan-02]
  /*!\ingroup date_format
   */
  inline std::string to_simple_string(const date_period& d) {
    return to_simple_string_type<char>(d);
  }

  // wrapper function for to_iso_(w)string(date_period)
  template<class charT>
  inline std::basic_string<charT> to_iso_string_type(const date_period& d) {
    charT sep = '/';
    std::basic_string<charT> s(date_time::date_formatter<date,date_time::iso_format<charT>,charT>::date_to_string(d.begin()));
    return s + sep + date_time::date_formatter<date,date_time::iso_format<charT>,charT>::date_to_string(d.last());
  }
  //! Date period to ISO 8601 standard format CCYYMMDD/CCYYMMDD. Example: 20021225/20021231
  /*!\ingroup date_format
   */
  inline std::string to_iso_string(const date_period& d) {
    return to_iso_string_type<char>(d);
  }


  // wrapper function for to_iso_extended_(w)string(date)
  template<class charT>
  inline std::basic_string<charT> to_iso_extended_string_type(const date& d) {
    return date_time::date_formatter<date,date_time::iso_extended_format<charT>,charT>::date_to_string(d);
  }
  //! Convert to ISO 8601 extended format string CCYY-MM-DD. Example 2002-12-31
  /*!\ingroup date_format
   */
  inline std::string to_iso_extended_string(const date& d) {
    return to_iso_extended_string_type<char>(d);
  }

  // wrapper function for to_iso_(w)string(date)
  template<class charT>
  inline std::basic_string<charT> to_iso_string_type(const date& d) {
    return date_time::date_formatter<date,date_time::iso_format<charT>,charT>::date_to_string(d);
  }
  //! Convert to ISO 8601 standard string YYYYMMDD. Example: 20021231
  /*!\ingroup date_format
   */
  inline std::string to_iso_string(const date& d) {
    return to_iso_string_type<char>(d);
  }

  
  

  // wrapper function for to_sql_(w)string(date)
  template<class charT>
  inline std::basic_string<charT> to_sql_string_type(const date& d) 
  {
    date::ymd_type ymd = d.year_month_day();
    std::basic_ostringstream<charT> ss;
    ss << ymd.year << "-"
       << std::setw(2) << std::setfill(ss.widen('0')) 
       << ymd.month.as_number() //solves problem with gcc 3.1 hanging
       << "-"
       << std::setw(2) << std::setfill(ss.widen('0')) 
       << ymd.day;
    return ss.str();
  }
  inline std::string to_sql_string(const date& d) {
    return to_sql_string_type<char>(d);
  }


#if !defined(BOOST_NO_STD_WSTRING)
  //! Convert date period to simple string. Example: [2002-Jan-01/2002-Jan-02]
  /*!\ingroup date_format
   */
  inline std::wstring to_simple_wstring(const date_period& d) {
    return to_simple_string_type<wchar_t>(d);
  }
  //! To YYYY-mmm-DD string where mmm 3 char month name. Example:  2002-Jan-01
  /*!\ingroup date_format
   */
  inline std::wstring to_simple_wstring(const date& d) {
    return to_simple_string_type<wchar_t>(d);
  }
  //! Date period to iso standard format CCYYMMDD/CCYYMMDD. Example: 20021225/20021231
  /*!\ingroup date_format
   */
  inline std::wstring to_iso_wstring(const date_period& d) {
    return to_iso_string_type<wchar_t>(d);
  }
  //! Convert to iso extended format string CCYY-MM-DD. Example 2002-12-31
  /*!\ingroup date_format
   */
  inline std::wstring to_iso_extended_wstring(const date& d) {
    return to_iso_extended_string_type<wchar_t>(d);
  }
  //! Convert to iso standard string YYYYMMDD. Example: 20021231
  /*!\ingroup date_format
   */
  inline std::wstring to_iso_wstring(const date& d) {
    return to_iso_string_type<wchar_t>(d);
  }
  inline std::wstring to_sql_wstring(const date& d) {
    return to_sql_string_type<wchar_t>(d);
  }
#endif // BOOST_NO_STD_WSTRING

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
