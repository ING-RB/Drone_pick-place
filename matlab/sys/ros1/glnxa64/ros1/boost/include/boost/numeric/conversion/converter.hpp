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

//  (c) Copyright Fernando Luis Cacciola Carballal 2000-2004
//  Use, modification, and distribution is subject to the Boost Software
//  License, Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

//  See library home page at http://www.boost.org/libs/numeric/conversion
//
// Contact the author at: fernando_cacciola@hotmail.com
// 
#ifndef BOOST_NUMERIC_CONVERSION_CONVERTER_FLC_12NOV2002_HPP
#define BOOST_NUMERIC_CONVERSION_CONVERTER_FLC_12NOV2002_HPP

#include "boost/numeric/conversion/conversion_traits.hpp"
#include "boost/numeric/conversion/converter_policies.hpp"

#include "boost/numeric/conversion/detail/converter.hpp"

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace numeric 
{

template<class T,
         class S,
         class Traits           = conversion_traits<T,S>,
         class OverflowHandler  = def_overflow_handler,
         class Float2IntRounder = Trunc< BOOST_DEDUCED_TYPENAME Traits::source_type>  ,
         class RawConverter     = raw_converter<Traits>,
         class UserRangeChecker = UseInternalRangeChecker
        >
struct converter : convdetail::get_converter_impl<Traits,
                                                  OverflowHandler,
                                                  Float2IntRounder,
                                                  RawConverter,
                                                  UserRangeChecker
                                                 >::type
{
  typedef Traits traits ;

  typedef typename Traits::argument_type argument_type ;
  typedef typename Traits::result_type   result_type   ;

  result_type operator() ( argument_type s ) const { return this->convert(s) ; }
} ;



template<class S,
         class OverflowHandler  = def_overflow_handler,
         class Float2IntRounder = Trunc<S>  ,
         class UserRangeChecker = UseInternalRangeChecker
        >
struct make_converter_from
{
  template<class T,
           class Traits       = conversion_traits<T,S>,
           class RawConverter = raw_converter<Traits>
          > 
  struct to
  {
    typedef converter<T,S,Traits,OverflowHandler,Float2IntRounder,RawConverter,UserRangeChecker> type ;
  } ;

} ;

} } // namespace mwboost::numeric

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
