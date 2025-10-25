// Copyright David Abrahams, Daniel Wallin 2003.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_AUX_PACK_TAG_DEDUCED_HPP
#define BOOST_PARAMETER_AUX_PACK_TAG_DEDUCED_HPP

#include <boost/parameter/aux_/set.hpp>
#include <boost/parameter/aux_/pack/tag_type.hpp>
#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/list.hpp>
#include <boost/mp11/utility.hpp>
#else
#include <boost/mpl/pair.hpp>
#include <boost/mpl/apply_wrap.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    // Tags a deduced argument Arg with the keyword tag of Spec using TagFn.
    // Returns the tagged argument and the mpl::set<> UsedArgs with the
    // tag of Spec inserted.
    template <typename UsedArgs, typename Spec, typename Arg, typename TagFn>
    struct tag_deduced
    {
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
        using type = ::mwboost::mp11::mp_list<
            ::mwboost::mp11::mp_apply_q<
                TagFn
              , ::mwboost::mp11::mp_list<
                    typename ::mwboost::parameter::aux::tag_type<Spec>::type
                  , Arg
                >
            >
#else
        typedef ::mwboost::mpl::pair<
            typename ::mwboost::mpl::apply_wrap2<
                TagFn
              , typename ::mwboost::parameter::aux::tag_type<Spec>::type
              , Arg
            >::type
#endif  // BOOST_PARAMETER_CAN_USE_MP11
          , typename ::mwboost::parameter::aux::insert_<
                UsedArgs
              , typename ::mwboost::parameter::aux::tag_type<Spec>::type
            >::type
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
        >;
#else
        > type;
#endif
    };
}}} // namespace mwboost::parameter::aux

#endif  // include guard

