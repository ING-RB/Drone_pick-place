// Copyright Daniel Wallin 2006.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_SET_060912_HPP
#define BOOST_PARAMETER_SET_060912_HPP

#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/list.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    typedef ::mwboost::mp11::mp_list<> set0;
}}} // namespace mwboost::parameter::aux

#include <boost/mp11/algorithm.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename S, typename K>
    struct insert_
    {
        using type = ::mwboost::mp11::mp_insert_c<S,0,K>;
    };
}}} // namespace mwboost::parameter::aux

#include <boost/mp11/integral.hpp>
#include <boost/mp11/utility.hpp>
#include <type_traits>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename Set, typename K>
    struct has_key_
    {
        using type = ::mwboost::mp11::mp_if<
            ::mwboost::mp11::mp_empty<Set>
          , ::mwboost::mp11::mp_false
          , ::std::is_same<
                ::mwboost::mp11::mp_find<Set,K>
              , ::mwboost::mp11::mp_size<Set>
            >
        >;
    };
}}} // namespace mwboost::parameter::aux

#elif BOOST_WORKAROUND(BOOST_BORLANDC, BOOST_TESTED_AT(0x564))
#include <boost/mpl/list.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    typedef ::mwboost::mpl::list0<> set0;
}}} // namespace mwboost::parameter::aux

#include <boost/mpl/push_front.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename Set, typename K>
    struct insert_ : ::mwboost::mpl::push_front<Set,K>
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/mpl/bool.hpp>
#include <boost/mpl/if.hpp>
#include <boost/mpl/end.hpp>
#include <boost/mpl/find.hpp>
#include <boost/type_traits/is_same.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename Set, typename K>
    struct has_key_
    {
        typedef typename ::mwboost::mpl::find<Set,K>::type iter;
        typedef typename ::mwboost::mpl::if_<
            ::mwboost::is_same<iter,typename ::mwboost::mpl::end<Set>::type>
          , ::mwboost::mpl::false_
          , ::mwboost::mpl::true_
        >::type type;
    };
}}} // namespace mwboost::parameter::aux

#else   // !BOOST_PARAMETER_CAN_USE_MP11 && Borland workarounds not needed
#include <boost/mpl/set/set0.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    typedef ::mwboost::mpl::set0<> set0;
}}} // namespace mwboost::parameter::aux

#include <boost/mpl/insert.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename Set, typename K>
    struct insert_ : ::mwboost::mpl::insert<Set,K>
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/mpl/has_key.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename Set, typename K>
    struct has_key_ : ::mwboost::mpl::has_key<Set,K>
    {
    };
}}} // namespace mwboost::parameter::aux

#endif  // BOOST_PARAMETER_CAN_USE_MP11 || Borland workarounds needed
#endif  // include guard

