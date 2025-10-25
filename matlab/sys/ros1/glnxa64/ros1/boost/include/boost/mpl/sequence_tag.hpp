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


#ifndef BOOST_MPL_SEQUENCE_TAG_HPP_INCLUDED
#define BOOST_MPL_SEQUENCE_TAG_HPP_INCLUDED

// Copyright Aleksey Gurtovoy 2000-2004
//
// Distributed under the Boost Software License, Version 1.0. 
// (See accompanying file LICENSE_1_0.txt or copy at 
// http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org/libs/mpl for documentation.

// $Id$
// $Date$
// $Revision$

#include <boost/mpl/sequence_tag_fwd.hpp>
#include <boost/mpl/aux_/has_tag.hpp>
#include <boost/mpl/aux_/has_begin.hpp>
#include <boost/mpl/aux_/na_spec.hpp>
#include <boost/mpl/aux_/is_msvc_eti_arg.hpp>
#include <boost/mpl/aux_/config/eti.hpp>
#include <boost/mpl/aux_/yes_no.hpp>
#include <boost/mpl/aux_/config/workaround.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace mpl {

// agurt, 27/nov/02: have to use a simplistic 'sequence_tag' implementation
// on MSVC to avoid dreadful "internal structure overflow" error
#if BOOST_WORKAROUND(BOOST_MSVC, < 1300) \
    || defined(BOOST_MPL_CFG_NO_HAS_XXX)

template<
      typename BOOST_MPL_AUX_NA_PARAM(Sequence)
    >
struct sequence_tag
{
    typedef typename Sequence::tag type;
};

#elif BOOST_WORKAROUND(BOOST_MSVC, == 1300)

// agurt, 07/feb/03: workaround for what seems to be MSVC 7.0-specific ETI issue

namespace aux {

template< bool >
struct sequence_tag_impl
{
    template< typename Sequence > struct result_
    {
        typedef typename Sequence::tag type;
    };
};

template<>
struct sequence_tag_impl<false>
{
    template< typename Sequence > struct result_
    {
        typedef int type;
    };
};

} // namespace aux

template<
      typename BOOST_MPL_AUX_NA_PARAM(Sequence)
    >
struct sequence_tag
    : aux::sequence_tag_impl< !aux::is_msvc_eti_arg<Sequence>::value >
        ::template result_<Sequence>
{
};

#else

namespace aux {

template< bool has_tag_, bool has_begin_ >
struct sequence_tag_impl
{
    // agurt 24/nov/02: MSVC 6.5 gets confused in 'sequence_tag_impl<true>' 
    // specialization below, if we name it 'result_' here
    template< typename Sequence > struct result2_;
};

#   define AUX_CLASS_SEQUENCE_TAG_SPEC(has_tag, has_begin, result_type) \
template<> struct sequence_tag_impl<has_tag,has_begin> \
{ \
    template< typename Sequence > struct result2_ \
    { \
        typedef result_type type; \
    }; \
}; \
/**/

AUX_CLASS_SEQUENCE_TAG_SPEC(true, true, typename Sequence::tag)
AUX_CLASS_SEQUENCE_TAG_SPEC(true, false, typename Sequence::tag)
AUX_CLASS_SEQUENCE_TAG_SPEC(false, true, nested_begin_end_tag)
AUX_CLASS_SEQUENCE_TAG_SPEC(false, false, non_sequence_tag)

#   undef AUX_CLASS_SEQUENCE_TAG_SPEC

} // namespace aux

template<
      typename BOOST_MPL_AUX_NA_PARAM(Sequence)
    >
struct sequence_tag
    : aux::sequence_tag_impl<
          ::mwboost::mpl::aux::has_tag<Sequence>::value
        , ::mwboost::mpl::aux::has_begin<Sequence>::value
        >::template result2_<Sequence>
{
};

#endif // BOOST_MSVC

BOOST_MPL_AUX_NA_SPEC(1, sequence_tag)

}}

#endif // BOOST_MPL_SEQUENCE_TAG_HPP_INCLUDED

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
