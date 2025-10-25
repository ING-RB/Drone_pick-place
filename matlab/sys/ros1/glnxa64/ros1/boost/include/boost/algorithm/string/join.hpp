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

//  Boost string_algo library join.hpp header file  ---------------------------//

//  Copyright Pavol Droba 2002-2006.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

//  See http://www.boost.org/ for updates, documentation, and revision history.

#ifndef BOOST_STRING_JOIN_HPP
#define BOOST_STRING_JOIN_HPP

#include <boost/algorithm/string/config.hpp>
#include <boost/algorithm/string/detail/sequence.hpp>
#include <boost/range/value_type.hpp>
#include <boost/range/as_literal.hpp>

/*! \file
    Defines join algorithm. 

    Join algorithm is a counterpart to split algorithms.
    It joins strings from a 'list' by adding user defined separator.
    Additionally there is a version that allows simple filtering
    by providing a predicate.
*/

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
    namespace algorithm {

//  join --------------------------------------------------------------//

        //! Join algorithm
        /*!
            This algorithm joins all strings in a 'list' into one long string.
            Segments are concatenated by given separator.

            \param Input A container that holds the input strings. It must be a container-of-containers.
            \param Separator A string that will separate the joined segments.
            \return Concatenated string.

            \note This function provides the strong exception-safety guarantee
        */
        template< typename SequenceSequenceT, typename Range1T>
        inline typename range_value<SequenceSequenceT>::type 
        join(
            const SequenceSequenceT& Input,
            const Range1T& Separator)
        {
            // Define working types
            typedef typename range_value<SequenceSequenceT>::type ResultT;
            typedef typename range_const_iterator<SequenceSequenceT>::type InputIteratorT;

            // Parse input
            InputIteratorT itBegin=::mwboost::begin(Input);
            InputIteratorT itEnd=::mwboost::end(Input);

            // Construct container to hold the result
            ResultT Result;
            
            // Append first element
            if(itBegin!=itEnd)
            {
                detail::insert(Result, ::mwboost::end(Result), *itBegin);
                ++itBegin;
            }

            for(;itBegin!=itEnd; ++itBegin)
            {
                // Add separator
                detail::insert(Result, ::mwboost::end(Result), ::mwboost::as_literal(Separator));
                // Add element
                detail::insert(Result, ::mwboost::end(Result), *itBegin);
            }

            return Result;
        }

// join_if ----------------------------------------------------------//

        //! Conditional join algorithm
        /*!
            This algorithm joins all strings in a 'list' into one long string.
            Segments are concatenated by given separator. Only segments that
            satisfy the predicate will be added to the result.

            \param Input A container that holds the input strings. It must be a container-of-containers.
            \param Separator A string that will separate the joined segments.
            \param Pred A segment selection predicate
            \return Concatenated string.

            \note This function provides the strong exception-safety guarantee
        */
        template< typename SequenceSequenceT, typename Range1T, typename PredicateT>
        inline typename range_value<SequenceSequenceT>::type 
        join_if(
            const SequenceSequenceT& Input,
            const Range1T& Separator,
            PredicateT Pred)
        {
            // Define working types
            typedef typename range_value<SequenceSequenceT>::type ResultT;
            typedef typename range_const_iterator<SequenceSequenceT>::type InputIteratorT;

            // Parse input
            InputIteratorT itBegin=::mwboost::begin(Input);
            InputIteratorT itEnd=::mwboost::end(Input);

            // Construct container to hold the result
            ResultT Result;

            // Roll to the first element that will be added
            while(itBegin!=itEnd && !Pred(*itBegin)) ++itBegin;
            // Add this element
            if(itBegin!=itEnd)
            {
                detail::insert(Result, ::mwboost::end(Result), *itBegin);
                ++itBegin;
            }

            for(;itBegin!=itEnd; ++itBegin)
            {
                if(Pred(*itBegin))
                {
                    // Add separator
                    detail::insert(Result, ::mwboost::end(Result), ::mwboost::as_literal(Separator));
                    // Add element
                    detail::insert(Result, ::mwboost::end(Result), *itBegin);
                }
            }

            return Result;
        }

    } // namespace algorithm

    // pull names to the boost namespace
    using algorithm::join;
    using algorithm::join_if;

} // namespace mwboost


#endif  // BOOST_STRING_JOIN_HPP


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
