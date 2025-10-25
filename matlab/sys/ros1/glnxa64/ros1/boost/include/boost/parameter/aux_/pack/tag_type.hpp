// Copyright David Abrahams, Daniel Wallin 2003.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_AUX_PACK_TAG_TYPE_HPP
#define BOOST_PARAMETER_AUX_PACK_TAG_TYPE_HPP

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    // helper for tag_type<...>, below.
    template <typename T>
    struct get_tag_type0
    {
        typedef typename T::key_type type;
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/deduced.hpp>
#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/utility.hpp>
#else
#include <boost/mpl/eval_if.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename T>
    struct get_tag_type
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
      : ::mwboost::mp11::mp_if<
#else
      : ::mwboost::mpl::eval_if<
#endif
            ::mwboost::parameter::aux::is_deduced0<T>
          , ::mwboost::parameter::aux::get_tag_type0<typename T::key_type>
          , ::mwboost::parameter::aux::get_tag_type0<T>
        >
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/required.hpp>
#include <boost/parameter/optional.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/integral.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename T>
    using tag_type = ::mwboost::mp11::mp_if<
        ::mwboost::mp11::mp_if<
            ::mwboost::parameter::aux::is_optional<T>
          , ::mwboost::mp11::mp_true
          , ::mwboost::parameter::aux::is_required<T>
        >
      , ::mwboost::parameter::aux::get_tag_type<T>
      , ::mwboost::mp11::mp_identity<T>
    >;
}}} // namespace mwboost::parameter::aux

#else   // !defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mpl/bool.hpp>
#include <boost/mpl/if.hpp>
#include <boost/mpl/identity.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename T>
    struct tag_type
      : ::mwboost::mpl::eval_if<
            typename ::mwboost::mpl::if_<
                ::mwboost::parameter::aux::is_optional<T>
              , ::mwboost::mpl::true_
              , ::mwboost::parameter::aux::is_required<T>
            >::type
          , ::mwboost::parameter::aux::get_tag_type<T>
          , ::mwboost::mpl::identity<T>
        >
    {
    };
}}} // namespace mwboost::parameter::aux

#endif  // BOOST_PARAMETER_CAN_USE_MP11
#endif  // include guard

