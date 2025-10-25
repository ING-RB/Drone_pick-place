// Copyright David Abrahams 2005.
// Copyright Cromwell D. Enage 2017.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_AUX_TAG_DWA2005610_HPP
#define BOOST_PARAMETER_AUX_TAG_DWA2005610_HPP

#include <boost/parameter/aux_/unwrap_cv_reference.hpp>
#include <boost/parameter/aux_/tagged_argument.hpp>
#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11) && \
    !BOOST_WORKAROUND(BOOST_MSVC, >= 1910)
// MSVC-14.1+ assigns rvalue references to tagged_argument instances
// instead of tagged_argument_rref instances with this code.
#include <boost/mp11/integral.hpp>
#include <boost/mp11/utility.hpp>
#include <type_traits>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux { 

    template <typename Keyword, typename Arg>
    struct tag_if_lvalue_reference
    {
        using type = ::mwboost::parameter::aux::tagged_argument_list_of_1<
            ::mwboost::parameter::aux::tagged_argument<
                Keyword
              , typename ::mwboost::parameter::aux
                ::unwrap_cv_reference<Arg>::type
            >
        >;
    };

    template <typename Keyword, typename Arg>
    struct tag_if_scalar
    {
        using type = ::mwboost::parameter::aux::tagged_argument_list_of_1<
            ::mwboost::parameter::aux
            ::tagged_argument<Keyword,typename ::std::add_const<Arg>::type>
        >;
    };

    template <typename Keyword, typename Arg>
    using tag_if_otherwise = ::mwboost::mp11::mp_if<
        ::std::is_scalar<typename ::std::remove_const<Arg>::type>
      , ::mwboost::parameter::aux::tag_if_scalar<Keyword,Arg>
      , ::mwboost::mp11::mp_identity<
            ::mwboost::parameter::aux::tagged_argument_list_of_1<
                ::mwboost::parameter::aux::tagged_argument_rref<Keyword,Arg>
            >
        >
    >;

    template <typename Keyword, typename Arg>
    using tag = ::mwboost::mp11::mp_if<
        ::mwboost::mp11::mp_if<
            ::std::is_lvalue_reference<Arg>
          , ::mwboost::mp11::mp_true
          , ::mwboost::parameter::aux::is_cv_reference_wrapper<Arg>
        >
      , ::mwboost::parameter::aux::tag_if_lvalue_reference<Keyword,Arg>
      , ::mwboost::parameter::aux::tag_if_otherwise<Keyword,Arg>
    >;
}}} // namespace mwboost::parameter::aux_

#elif defined(BOOST_PARAMETER_HAS_PERFECT_FORWARDING)
#include <boost/mpl/bool.hpp>
#include <boost/mpl/if.hpp>
#include <boost/mpl/eval_if.hpp>
#include <boost/mpl/identity.hpp>
#include <boost/type_traits/add_const.hpp>
#include <boost/type_traits/is_scalar.hpp>
#include <boost/type_traits/is_lvalue_reference.hpp>
#include <boost/type_traits/remove_const.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux { 

    template <typename Keyword, typename ActualArg>
    struct tag
    {
        typedef typename ::mwboost::parameter::aux
        ::unwrap_cv_reference<ActualArg>::type Arg;
        typedef typename ::mwboost::add_const<Arg>::type ConstArg;
        typedef typename ::mwboost::remove_const<Arg>::type MutArg;
        typedef typename ::mwboost::mpl::eval_if<
            typename ::mwboost::mpl::if_<
                ::mwboost::is_lvalue_reference<ActualArg>
              , ::mwboost::mpl::true_
              , ::mwboost::parameter::aux::is_cv_reference_wrapper<ActualArg>
            >::type
          , ::mwboost::mpl::identity<
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
                ::mwboost::parameter::aux::tagged_argument_list_of_1<
#endif
                    ::mwboost::parameter::aux::tagged_argument<Keyword,Arg>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
                >
#endif
            >
          , ::mwboost::mpl::if_<
                ::mwboost::is_scalar<MutArg>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
              , ::mwboost::parameter::aux::tagged_argument_list_of_1<
                    ::mwboost::parameter::aux::tagged_argument<Keyword,ConstArg>
                >
              , ::mwboost::parameter::aux::tagged_argument_list_of_1<
                    ::mwboost::parameter::aux::tagged_argument_rref<Keyword,Arg>
                >
#else
              , ::mwboost::parameter::aux::tagged_argument<Keyword,ConstArg>
              , ::mwboost::parameter::aux::tagged_argument_rref<Keyword,Arg>
#endif
            >
        >::type type;
    };
}}} // namespace mwboost::parameter::aux_

#else   // !defined(BOOST_PARAMETER_HAS_PERFECT_FORWARDING)

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux { 

    template <
        typename Keyword
      , typename Arg
#if BOOST_WORKAROUND(BOOST_BORLANDC, BOOST_TESTED_AT(0x564))
      , typename = typename ::mwboost::parameter::aux
        ::is_cv_reference_wrapper<Arg>::type
#endif
    >
    struct tag
    {
        typedef ::mwboost::parameter::aux::tagged_argument<
            Keyword
          , typename ::mwboost::parameter::aux::unwrap_cv_reference<Arg>::type
        > type;
    };
}}} // namespace mwboost::parameter::aux_

#if BOOST_WORKAROUND(BOOST_BORLANDC, BOOST_TESTED_AT(0x564))
#include <boost/mpl/bool.hpp>
#include <boost/type_traits/remove_reference.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux { 

    template <typename Keyword, typename Arg>
    struct tag<Keyword,Arg,::mwboost::mpl::false_>
    {
        typedef ::mwboost::parameter::aux::tagged_argument<
            Keyword
          , typename ::mwboost::remove_reference<Arg>::type
        > type;
    };
}}} // namespace mwboost::parameter::aux_

#endif  // Borland workarounds needed.
#endif  // MP11 or perfect forwarding support
#endif  // include guard

