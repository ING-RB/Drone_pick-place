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
    Copyright (c) 2001-2011 Joel de Guzman

    Distributed under the Boost Software License, Version 1.0. (See accompanying
    file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
==============================================================================*/
#if !defined(FUSION_ADVANCE_09172005_1146)
#define FUSION_ADVANCE_09172005_1146

#include <boost/fusion/support/config.hpp>
#include <boost/fusion/iterator/detail/advance.hpp>
#include <boost/fusion/support/category_of.hpp>

#include <boost/mpl/int.hpp>
#include <boost/mpl/assert.hpp>
#include <boost/type_traits/is_same.hpp>
#include <boost/fusion/support/tag_of.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace fusion
{
    struct random_access_traversal_tag;

    // Special tags:
    struct iterator_facade_tag; // iterator facade tag
    struct boost_array_iterator_tag; // mwboost::array iterator tag
    struct mpl_iterator_tag; // mpl sequence iterator tag
    struct std_pair_iterator_tag; // std::pair iterator tag

    namespace extension
    {
        template <typename Tag>
        struct advance_impl
        {
            // default implementation
            template <typename Iterator, typename N>
            struct apply :
                mpl::if_c<
                    (N::value > 0)
                  , advance_detail::forward<Iterator, N::value>
                  , advance_detail::backward<Iterator, N::value>
                >::type
            {
                BOOST_MPL_ASSERT_NOT((traits::is_random_access<Iterator>));
            };
        };

        template <>
        struct advance_impl<iterator_facade_tag>
        {
            template <typename Iterator, typename N>
            struct apply : Iterator::template advance<Iterator, N> {};
        };

        template <>
        struct advance_impl<boost_array_iterator_tag>;

        template <>
        struct advance_impl<mpl_iterator_tag>;

        template <>
        struct advance_impl<std_pair_iterator_tag>;
    }

    namespace result_of
    {
        template <typename Iterator, int N>
        struct advance_c
            : extension::advance_impl<typename detail::tag_of<Iterator>::type>::template apply<Iterator, mpl::int_<N> >
        {};

        template <typename Iterator, typename N>
        struct advance
            : extension::advance_impl<typename detail::tag_of<Iterator>::type>::template apply<Iterator, N>
        {};
    }

    template <int N, typename Iterator>
    BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
    inline typename result_of::advance_c<Iterator, N>::type const
    advance_c(Iterator const& i)
    {
        return result_of::advance_c<Iterator, N>::call(i);
    }

    template<typename N, typename Iterator>
    BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
    inline typename result_of::advance<Iterator, N>::type const
    advance(Iterator const& i)
    {
        return result_of::advance<Iterator, N>::call(i);
    }

}} // namespace mwboost::fusion

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
