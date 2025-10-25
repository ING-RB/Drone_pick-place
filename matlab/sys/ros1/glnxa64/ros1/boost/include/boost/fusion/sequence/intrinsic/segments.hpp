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

/*=============================================================================
    Copyright (c) 2006 Eric Niebler

    Distributed under the Boost Software License, Version 1.0. (See accompanying 
    file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
==============================================================================*/
#if !defined(BOOST_FUSION_SEGMENTS_04052005_1141)
#define BOOST_FUSION_SEGMENTS_04052005_1141

#include <boost/fusion/support/config.hpp>
#include <boost/type_traits/is_const.hpp>
#include <boost/utility/enable_if.hpp>
#include <boost/fusion/sequence/intrinsic_fwd.hpp>
#include <boost/fusion/support/tag_of.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace fusion
{
    // Special tags:
    struct sequence_facade_tag;
    struct iterator_range_tag;

    // segments: returns a sequence of sequences
    namespace extension
    {
        template <typename Tag>
        struct segments_impl
        {
            template <typename Sequence>
            struct apply {};
        };

        template <>
        struct segments_impl<sequence_facade_tag>
        {
            template <typename Sequence>
            struct apply : Sequence::template segments<Sequence> {};
        }; 

        template <>
        struct segments_impl<iterator_range_tag>;
    }

    namespace result_of
    {
        template <typename Sequence>
        struct segments
        {
            typedef typename traits::tag_of<Sequence>::type tag_type;

            typedef typename
                extension::segments_impl<tag_type>::template apply<Sequence>::type
            type;
        };
    }

    template <typename Sequence>
    BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
    inline typename
        lazy_disable_if<
            is_const<Sequence>
          , result_of::segments<Sequence>
        >::type
    segments(Sequence& seq)
    {
        typedef typename traits::tag_of<Sequence>::type tag_type;
        return extension::segments_impl<tag_type>::template apply<Sequence>::call(seq);
    }

    template <typename Sequence>
    BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
    inline typename result_of::segments<Sequence const>::type
    segments(Sequence const& seq)
    {
        typedef typename traits::tag_of<Sequence const>::type tag_type;
        return extension::segments_impl<tag_type>::template apply<Sequence const>::call(seq);
    }
}}

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
