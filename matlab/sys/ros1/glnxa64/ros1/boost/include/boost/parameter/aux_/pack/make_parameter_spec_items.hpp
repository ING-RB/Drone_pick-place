// Copyright Cromwell D. Enage 2017.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_AUX_PACK_MAKE_PARAMETER_SPEC_ITEMS_HPP
#define BOOST_PARAMETER_AUX_PACK_MAKE_PARAMETER_SPEC_ITEMS_HPP

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    // This recursive metafunction forwards successive elements of
    // parameters::parameter_spec to make_deduced_items<>.
    // -- Cromwell D. Enage
    template <typename SpecSeq>
    struct make_deduced_list;

    // Helper for match_parameters_base_cond<...>, below.
    template <typename ArgumentPackAndError, typename SpecSeq>
    struct match_parameters_base_cond_helper;

    // Helper metafunction for make_parameter_spec_items<...>, below.
    template <typename SpecSeq, typename ...Args>
    struct make_parameter_spec_items_helper;
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/void.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename SpecSeq>
    struct make_parameter_spec_items_helper<SpecSeq>
    {
        typedef ::mwboost::parameter::void_ type;
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/pack/make_deduced_items.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/list.hpp>
#else
#include <boost/mpl/front.hpp>
#include <boost/mpl/pop_front.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename SpecSeq>
    struct make_deduced_list_not_empty
      : ::mwboost::parameter::aux::make_deduced_items<
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
            ::mwboost::mp11::mp_front<SpecSeq>
#else
            typename ::mwboost::mpl::front<SpecSeq>::type
#endif
          , ::mwboost::parameter::aux::make_deduced_list<
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
                ::mwboost::mp11::mp_pop_front<SpecSeq>
#else
                typename ::mwboost::mpl::pop_front<SpecSeq>::type
#endif
            >
        >
    {
    };
}}} // namespace mwboost::parameter::aux

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/utility.hpp>
#else
#include <boost/mpl/eval_if.hpp>
#include <boost/mpl/empty.hpp>
#include <boost/mpl/identity.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename SpecSeq>
    struct make_deduced_list
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
      : ::mwboost::mp11::mp_if<
            ::mwboost::mp11::mp_empty<SpecSeq>
          , ::mwboost::mp11::mp_identity< ::mwboost::parameter::void_>
#else
      : ::mwboost::mpl::eval_if<
            ::mwboost::mpl::empty<SpecSeq>
          , ::mwboost::mpl::identity< ::mwboost::parameter::void_>
#endif
          , ::mwboost::parameter::aux::make_deduced_list_not_empty<SpecSeq>
        >
    {
    };
}}} // namespace mwboost::parameter::aux

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <type_traits>
#else
#include <boost/mpl/bool.hpp>
#include <boost/mpl/pair.hpp>
#include <boost/mpl/if.hpp>
#include <boost/type_traits/is_same.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename ArgumentPackAndError>
    struct is_arg_pack_error_void
      : ::mwboost::mpl::if_<
            ::mwboost::is_same<
                typename ::mwboost::mpl::second<ArgumentPackAndError>::type
              , ::mwboost::parameter::void_
            >
          , ::mwboost::mpl::true_
          , ::mwboost::mpl::false_
        >::type
    {
    };
}}} // namespace mwboost::parameter::aux

#endif  // BOOST_PARAMETER_CAN_USE_MP11

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    // Checks if the arguments match the criteria of overload resolution.
    // If NamedList satisfies the PS0, PS1, ..., this is a metafunction
    // returning parameters.  Otherwise it has no nested ::type.
    template <typename ArgumentPackAndError, typename SpecSeq>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
    using match_parameters_base_cond = ::mwboost::mp11::mp_if<
        ::mwboost::mp11::mp_empty<SpecSeq>
      , ::std::is_same<
            ::mwboost::mp11::mp_at_c<ArgumentPackAndError,1>
          , ::mwboost::parameter::void_
        >
      , ::mwboost::parameter::aux::match_parameters_base_cond_helper<
            ArgumentPackAndError
          , SpecSeq
        >
    >;
#else
    struct match_parameters_base_cond
      : ::mwboost::mpl::eval_if<
            ::mwboost::mpl::empty<SpecSeq>
          , ::mwboost::parameter::aux
            ::is_arg_pack_error_void<ArgumentPackAndError>
          , ::mwboost::parameter::aux::match_parameters_base_cond_helper<
                ArgumentPackAndError
              , SpecSeq
            >
        >
    {
    };
#endif  // BOOST_PARAMETER_CAN_USE_MP11
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/pack/satisfies.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename ArgumentPackAndError, typename SpecSeq>
    struct match_parameters_base_cond_helper
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
      : ::mwboost::mp11::mp_if<
#else
      : ::mwboost::mpl::eval_if<
#endif
            ::mwboost::parameter::aux::satisfies_requirements_of<
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
                ::mwboost::mp11::mp_at_c<ArgumentPackAndError,0>
              , ::mwboost::mp11::mp_front<SpecSeq>
#else
                typename ::mwboost::mpl::first<ArgumentPackAndError>::type
              , typename ::mwboost::mpl::front<SpecSeq>::type
#endif
            >
          , ::mwboost::parameter::aux::match_parameters_base_cond<
                ArgumentPackAndError
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
              , ::mwboost::mp11::mp_pop_front<SpecSeq>
#else
              , typename ::mwboost::mpl::pop_front<SpecSeq>::type
#endif
            >
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
          , ::mwboost::mp11::mp_false
#else
          , ::mwboost::mpl::false_
#endif
        >
    {
    };

    // This parameters item chaining metafunction class does not require
    // the lengths of the SpecSeq and of Args parameter pack to match.
    // Used by argument_pack to build the items in the resulting arg_list.
    // -- Cromwell D. Enage
    template <typename SpecSeq, typename ...Args>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
    using make_parameter_spec_items = ::mwboost::mp11::mp_if<
        ::mwboost::mp11::mp_empty<SpecSeq>
      , ::mwboost::mp11::mp_identity< ::mwboost::parameter::void_>
      , ::mwboost::parameter::aux
        ::make_parameter_spec_items_helper<SpecSeq,Args...>
    >;
#else
    struct make_parameter_spec_items
      : ::mwboost::mpl::eval_if<
            ::mwboost::mpl::empty<SpecSeq>
          , ::mwboost::mpl::identity< ::mwboost::parameter::void_>
          , ::mwboost::parameter::aux
            ::make_parameter_spec_items_helper<SpecSeq,Args...>
        >
    {
    };
#endif
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/pack/make_items.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename SpecSeq, typename A0, typename ...Args>
    struct make_parameter_spec_items_helper<SpecSeq,A0,Args...>
      : ::mwboost::parameter::aux::make_items<
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
            ::mwboost::mp11::mp_front<SpecSeq>
#else
            typename ::mwboost::mpl::front<SpecSeq>::type
#endif
          , A0
          , ::mwboost::parameter::aux::make_parameter_spec_items<
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
                ::mwboost::mp11::mp_pop_front<SpecSeq>
#else
                typename ::mwboost::mpl::pop_front<SpecSeq>::type
#endif
              , Args...
            >
        >
    {
    };
}}} // namespace mwboost::parameter::aux

#endif  // include guard

