// Copyright David Abrahams, Daniel Wallin 2003.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_AUX_PACK_PREDICATE_HPP
#define BOOST_PARAMETER_AUX_PACK_PREDICATE_HPP

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    // helper for get_predicate<...>, below
    template <typename T>
    struct get_predicate_or_default
    {
        typedef T type;
    };

    // helper for predicate<...>, below
    template <typename T>
    struct get_predicate
      : ::mwboost::parameter::aux
        ::get_predicate_or_default<typename T::predicate>
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/use_default.hpp>
#include <boost/parameter/aux_/always_true_predicate.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <>
    struct get_predicate_or_default< ::mwboost::parameter::aux::use_default>
    {
        typedef ::mwboost::parameter::aux::always_true_predicate type;
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/required.hpp>
#include <boost/parameter/optional.hpp>
#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/integral.hpp>
#include <boost/mp11/utility.hpp>
#else
#include <boost/mpl/bool.hpp>
#include <boost/mpl/if.hpp>
#include <boost/mpl/eval_if.hpp>
#include <boost/mpl/identity.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename T>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
    using predicate = ::mwboost::mp11::mp_if<
        ::mwboost::mp11::mp_if<
            ::mwboost::parameter::aux::is_optional<T>
          , ::mwboost::mp11::mp_true
          , ::mwboost::parameter::aux::is_required<T>
        >
      , ::mwboost::parameter::aux::get_predicate<T>
      , ::mwboost::mp11::mp_identity<
            ::mwboost::parameter::aux::always_true_predicate
        >
    >;
#else
    struct predicate
      : ::mwboost::mpl::eval_if<
            typename ::mwboost::mpl::if_<
                ::mwboost::parameter::aux::is_optional<T>
              , ::mwboost::mpl::true_
              , ::mwboost::parameter::aux::is_required<T>
            >::type
          , ::mwboost::parameter::aux::get_predicate<T>
          , ::mwboost::mpl::identity<
                ::mwboost::parameter::aux::always_true_predicate
            >
        >
    {
    };
#endif  // BOOST_PARAMETER_CAN_USE_MP11
}}} // namespace mwboost::parameter::aux

#endif  // include guard

