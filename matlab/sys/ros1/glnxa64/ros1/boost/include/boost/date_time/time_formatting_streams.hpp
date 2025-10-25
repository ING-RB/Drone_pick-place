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

#ifndef DATE_TIME_TIME_FORMATTING_STREAMS_HPP___
#define DATE_TIME_TIME_FORMATTING_STREAMS_HPP___

/* Copyright (c) 2002,2003 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland, Bart Garst
 * $Date$
 */

#include <boost/date_time/compiler_config.hpp>

#ifndef BOOST_DATE_TIME_NO_LOCALE

#include <locale>
#include <iomanip>
#include <iostream>
#include <boost/date_time/date_formatting_locales.hpp>
#include <boost/date_time/time_resolution_traits.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace date_time {


  //! Put a time type into a stream using appropriate facets
  template<class time_duration_type,
           class charT = char>
  class ostream_time_duration_formatter
  {
  public:
    typedef std::basic_ostream<charT> ostream_type;
    typedef typename time_duration_type::fractional_seconds_type fractional_seconds_type;

    //! Put time into an ostream 
    static void duration_put(const time_duration_type& td, 
                             ostream_type& os)
    {
      if(td.is_special()) {
        os << td.get_rep(); 
      }
      else {
        charT fill_char = '0';
        if(td.is_negative()) {
          os << '-';
        }
        os  << std::setw(2) << std::setfill(fill_char) 
            << absolute_value(td.hours()) << ":";
        os  << std::setw(2) << std::setfill(fill_char) 
            << absolute_value(td.minutes()) << ":";
        os  << std::setw(2) << std::setfill(fill_char) 
            << absolute_value(td.seconds());
        fractional_seconds_type frac_sec = 
          absolute_value(td.fractional_seconds());
        if (frac_sec != 0) {
          os  << "." 
              << std::setw(time_duration_type::num_fractional_digits())
              << std::setfill(fill_char)
              << frac_sec;
        }
      } // else
    } // duration_put
  }; //class ostream_time_duration_formatter

  //! Put a time type into a stream using appropriate facets
  template<class time_type,
           class charT = char>
  class ostream_time_formatter
  {
  public:
    typedef std::basic_ostream<charT> ostream_type;
    typedef typename time_type::date_type date_type;
    typedef typename time_type::time_duration_type time_duration_type;
    typedef ostream_time_duration_formatter<time_duration_type, charT> duration_formatter;

    //! Put time into an ostream 
    static void time_put(const time_type& t, 
                         ostream_type& os)
    {
      date_type d = t.date();
      os << d;
      if(!d.is_infinity() && !d.is_not_a_date())
      {
        os << " "; //TODO: fix the separator here.
        duration_formatter::duration_put(t.time_of_day(), os);
      }
      
    } // time_to_ostream    
  }; //class ostream_time_formatter


  //! Put a time period into a stream using appropriate facets
  template<class time_period_type,
           class charT = char>
  class ostream_time_period_formatter
  {
  public:
    typedef std::basic_ostream<charT> ostream_type;
    typedef typename time_period_type::point_type time_type;
    typedef ostream_time_formatter<time_type, charT> time_formatter;

    //! Put time into an ostream 
    static void period_put(const time_period_type& tp, 
                           ostream_type& os)
    {
      os << '['; //TODO: facet or manipulator for periods?
      time_formatter::time_put(tp.begin(), os);
      os << '/'; //TODO: facet or manipulator for periods?
      time_formatter::time_put(tp.last(), os);
      os << ']'; 

    } // period_put

  }; //class ostream_time_period_formatter


  
} } //namespace date_time

#endif //BOOST_DATE_TIME_NO_LOCALE

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
