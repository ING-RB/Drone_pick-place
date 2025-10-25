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

// Boost.Range library
//
//  Copyright Thorsten Ottosen 2003-2004. Use, modification and
//  distribution is subject to the Boost Software License, Version
//  1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)
//
// For more information, see http://www.boost.org/libs/range/
//

#ifndef BOOST_RANGE_ITERATOR_HPP
#define BOOST_RANGE_ITERATOR_HPP

#if defined(_MSC_VER)
# pragma once
#endif

#include <boost/range/config.hpp>
#include <boost/range/range_fwd.hpp>
#include <boost/range/mutable_iterator.hpp>
#include <boost/range/const_iterator.hpp>
#include <boost/type_traits/is_const.hpp>
#include <boost/type_traits/remove_const.hpp>
#include <boost/mpl/eval_if.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

#if BOOST_WORKAROUND(BOOST_MSVC, == 1310)  

    namespace range_detail_vc7_1  
    {  
       template< typename C, typename Sig = void(C) >  
       struct range_iterator  
       {  
           typedef BOOST_RANGE_DEDUCED_TYPENAME   
               mpl::eval_if_c< is_const<C>::value,   
                               range_const_iterator< typename remove_const<C>::type >,  
                               range_mutable_iterator<C> >::type type;  
       };  
    
       template< typename C, typename T >  
       struct range_iterator< C, void(T[]) >  
       {  
           typedef T* type;  
       };       
    }  
    
    template< typename C, typename Enabler=void >
    struct range_iterator
    {

        typedef BOOST_RANGE_DEDUCED_TYPENAME  
               range_detail_vc7_1::range_iterator<C>::type type;  

    };

#else

    template< typename C, typename Enabler=void >
    struct range_iterator
      : mpl::if_c<
            is_const<typename remove_reference<C>::type>::value,
            range_const_iterator<typename remove_const<typename remove_reference<C>::type>::type>,
            range_mutable_iterator<typename remove_reference<C>::type>
        >::type
    {
    };

#endif

} // namespace mwboost

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
