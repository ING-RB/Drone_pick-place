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
#if !defined(FUSION_MPL_ITERATOR_05052005_0731)
#define FUSION_MPL_ITERATOR_05052005_0731

#include <boost/fusion/support/config.hpp>
#include <boost/fusion/support/detail/mpl_iterator_category.hpp>
#include <boost/fusion/iterator/iterator_facade.hpp>
#include <boost/type_traits/remove_const.hpp>
#include <boost/mpl/deref.hpp>
#include <boost/mpl/next.hpp>
#include <boost/mpl/prior.hpp>
#include <boost/mpl/advance.hpp>
#include <boost/mpl/distance.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace fusion
{
    template <typename Iterator_>
    struct mpl_iterator
        : iterator_facade<
            mpl_iterator<Iterator_>
          , typename detail::mpl_iterator_category<typename Iterator_::category>::type
        >
    {
        typedef typename remove_const<Iterator_>::type iterator_type;

        template <typename Iterator>
        struct value_of : mpl::deref<typename Iterator::iterator_type> {};

        template <typename Iterator>
        struct deref
        {
            typedef typename mpl::deref<
                typename Iterator::iterator_type>::type
            type;

            BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
            static type
            call(Iterator)
            {
                return type();
            }
        };

        template <typename Iterator>
        struct next
        {
            typedef mpl_iterator<
                typename mpl::next<typename Iterator::iterator_type>::type> 
            type;

            BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
            static type
            call(Iterator)
            {
                return type();
            }
        };

        template <typename Iterator>
        struct prior
        {
            typedef mpl_iterator<
                typename mpl::prior<typename Iterator::iterator_type>::type> 
            type;

            BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
            static type
            call(Iterator)
            {
                return type();
            }
        };

        template <typename Iterator, typename N>
        struct advance
        {
            typedef mpl_iterator<
                typename mpl::advance<typename Iterator::iterator_type, N>::type>
            type;

            BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
            static type
            call(Iterator const& /*i*/)
            {
                return type();
            }
        };

        template <typename I1, typename I2>
        struct distance : 
            mpl::distance<
                typename I1::iterator_type
              , typename I2::iterator_type>
        {
            typedef typename 
                mpl::distance<
                    typename I1::iterator_type
                  , typename I2::iterator_type
                >::type
            type;
            
            BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
            static type
            call(I1 const&, I2 const&)
            {
                return type();
            }
        };
    };
}}

#ifdef BOOST_FUSION_WORKAROUND_FOR_LWG_2408
namespace std
{
    template <typename Iterator>
    struct iterator_traits< ::mwboost::fusion::mpl_iterator<Iterator> >
    { };
}
#endif

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
