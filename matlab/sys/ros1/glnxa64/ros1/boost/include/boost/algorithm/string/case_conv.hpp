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

//  Boost string_algo library case_conv.hpp header file  ---------------------------//

//  Copyright Pavol Droba 2002-2003.
//
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

//  See http://www.boost.org/ for updates, documentation, and revision history.

#ifndef BOOST_STRING_CASE_CONV_HPP
#define BOOST_STRING_CASE_CONV_HPP

#include <boost/algorithm/string/config.hpp>
#include <algorithm>
#include <locale>
#include <boost/iterator/transform_iterator.hpp>

#include <boost/range/as_literal.hpp>
#include <boost/range/begin.hpp>
#include <boost/range/end.hpp>
#include <boost/range/value_type.hpp>

#include <boost/algorithm/string/detail/case_conv.hpp>

/*! \file
    Defines sequence case-conversion algorithms.
    Algorithms convert each element in the input sequence to the
    desired case using provided locales.
*/

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
    namespace algorithm {

//  to_lower  -----------------------------------------------//

        //! Convert to lower case
        /*!
            Each element of the input sequence is converted to lower
            case. The result is a copy of the input converted to lower case.
            It is returned as a sequence or copied to the output iterator.

            \param Output An output iterator to which the result will be copied
            \param Input An input range
            \param Loc A locale used for conversion
            \return 
                An output iterator pointing just after the last inserted character or
                a copy of the input

            \note The second variant of this function provides the strong exception-safety guarantee
                
        */
        template<typename OutputIteratorT, typename RangeT>
        inline OutputIteratorT 
        to_lower_copy(
            OutputIteratorT Output,
            const RangeT& Input,
            const std::locale& Loc=std::locale())
        {
            return ::mwboost::algorithm::detail::transform_range_copy( 
               Output,
               ::mwboost::as_literal(Input),
               ::mwboost::algorithm::detail::to_lowerF<
                    typename range_value<RangeT>::type >(Loc));
        }

        //! Convert to lower case
        /*!
            \overload
        */
        template<typename SequenceT>
        inline SequenceT to_lower_copy( 
            const SequenceT& Input, 
            const std::locale& Loc=std::locale())
        {
            return ::mwboost::algorithm::detail::transform_range_copy<SequenceT>(
                Input,
                ::mwboost::algorithm::detail::to_lowerF<
                    typename range_value<SequenceT>::type >(Loc));
        }

        //! Convert to lower case
        /*!
            Each element of the input sequence is converted to lower
            case. The input sequence is modified in-place.

            \param Input A range
            \param Loc a locale used for conversion
        */
        template<typename WritableRangeT>
        inline void to_lower( 
            WritableRangeT& Input, 
            const std::locale& Loc=std::locale())
        {
            ::mwboost::algorithm::detail::transform_range(
                ::mwboost::as_literal(Input),
                ::mwboost::algorithm::detail::to_lowerF<
                    typename range_value<WritableRangeT>::type >(Loc));
        }
        
//  to_upper  -----------------------------------------------//

        //! Convert to upper case
        /*!
            Each element of the input sequence is converted to upper
            case. The result is a copy of the input converted to upper case.
            It is returned as a sequence or copied to the output iterator

            \param Output An output iterator to which the result will be copied
            \param Input An input range
            \param Loc A locale used for conversion
            \return 
                An output iterator pointing just after the last inserted character or
                a copy of the input

            \note The second variant of this function provides the strong exception-safety guarantee
        */
        template<typename OutputIteratorT, typename RangeT>
        inline OutputIteratorT 
        to_upper_copy(
            OutputIteratorT Output,
            const RangeT& Input,
            const std::locale& Loc=std::locale())
        {
            return ::mwboost::algorithm::detail::transform_range_copy( 
               Output,
               ::mwboost::as_literal(Input),
               ::mwboost::algorithm::detail::to_upperF<
                    typename range_value<RangeT>::type >(Loc));
        }

        //! Convert to upper case
        /*!
            \overload
        */
        template<typename SequenceT>
        inline SequenceT to_upper_copy( 
            const SequenceT& Input, 
            const std::locale& Loc=std::locale())
        {
            return ::mwboost::algorithm::detail::transform_range_copy<SequenceT>(
                Input,
                ::mwboost::algorithm::detail::to_upperF<
                    typename range_value<SequenceT>::type >(Loc));
        }

        //! Convert to upper case
        /*!
            Each element of the input sequence is converted to upper
            case. The input sequence is modified in-place.

            \param Input An input range
            \param Loc a locale used for conversion
        */
        template<typename WritableRangeT>
        inline void to_upper( 
            WritableRangeT& Input, 
            const std::locale& Loc=std::locale())
        {
            ::mwboost::algorithm::detail::transform_range(
                ::mwboost::as_literal(Input),
                ::mwboost::algorithm::detail::to_upperF<
                    typename range_value<WritableRangeT>::type >(Loc));
        }

    } // namespace algorithm

    // pull names to the boost namespace
    using algorithm::to_lower;
    using algorithm::to_lower_copy;
    using algorithm::to_upper;
    using algorithm::to_upper_copy;

} // namespace mwboost

#endif  // BOOST_STRING_CASE_CONV_HPP

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
