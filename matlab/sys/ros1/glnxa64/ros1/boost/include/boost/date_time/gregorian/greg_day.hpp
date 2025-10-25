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

#ifndef GREG_DAY_HPP___
#define GREG_DAY_HPP___

/* Copyright (c) 2002,2003,2020 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the 
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland 
 * $Date$
 */

#include <boost/date_time/constrained_value.hpp>
#include <boost/date_time/compiler_config.hpp>
#include <stdexcept>
#include <string>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace gregorian {

  //! Exception type for gregorian day of month (1..31)
  struct BOOST_SYMBOL_VISIBLE bad_day_of_month : public std::out_of_range
  {
    bad_day_of_month() : 
      std::out_of_range(std::string("Day of month value is out of range 1..31")) 
    {}
    //! Allow other classes to throw with unique string for bad day like Feb 29
    bad_day_of_month(const std::string& s) : 
      std::out_of_range(s) 
    {}
  };
  //! Policy class that declares error handling and day of month ranges
  typedef CV::simple_exception_policy<unsigned short, 1, 31, bad_day_of_month> greg_day_policies;

  //! Generated represetation for gregorian day of month
  typedef CV::constrained_value<greg_day_policies> greg_day_rep;

  //! Represent a day of the month (range 1 - 31) 
  /*! This small class allows for simple conversion an integer value into
      a day of the month for a standard gregorian calendar.  The type 
      is automatically range checked so values outside of the range 1-31
      will cause a bad_day_of_month exception
  */
  class BOOST_SYMBOL_VISIBLE greg_day : public greg_day_rep {
  public:
    BOOST_CXX14_CONSTEXPR greg_day(value_type day_of_month) : greg_day_rep(day_of_month) {}
    BOOST_CXX14_CONSTEXPR value_type as_number() const {return value_;}
    BOOST_CXX14_CONSTEXPR operator value_type()  const {return value_;}
  private:
    
  };



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
