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

// Copyright (C) 2017 Michel Morin.
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_ITERATOR_DISTANCE_HPP
#define BOOST_ITERATOR_DISTANCE_HPP

#include <boost/config.hpp>
#include <boost/iterator/iterator_categories.hpp>
#include <boost/iterator/iterator_traits.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace iterators {

    namespace detail {
        template <typename SinglePassIterator>
        inline BOOST_CXX14_CONSTEXPR typename iterator_difference<SinglePassIterator>::type
        distance_impl(
            SinglePassIterator first
          , SinglePassIterator last
          , single_pass_traversal_tag
        )
        {
            typename iterator_difference<SinglePassIterator>::type n = 0;
            while (first != last) {
                ++first;
                ++n;
            }
            return n;
        }

        template <typename RandomAccessIterator>
        inline BOOST_CXX14_CONSTEXPR typename iterator_difference<RandomAccessIterator>::type
        distance_impl(
            RandomAccessIterator first
          , RandomAccessIterator last
          , random_access_traversal_tag
        )
        {
            return last - first;
        }
    }

    namespace distance_adl_barrier {
        template <typename SinglePassIterator>
        inline BOOST_CXX14_CONSTEXPR typename iterator_difference<SinglePassIterator>::type
        distance(SinglePassIterator first, SinglePassIterator last)
        {
            return detail::distance_impl(
                first, last, typename iterator_traversal<SinglePassIterator>::type()
            );
        }
    }

    using namespace distance_adl_barrier;

} // namespace iterators

using namespace iterators::distance_adl_barrier;

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
