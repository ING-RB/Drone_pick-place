// Copyright Cromwell D. Enage 2018.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_AUGMENT_PREDICATE_HPP
#define BOOST_PARAMETER_AUGMENT_PREDICATE_HPP

#include <boost/parameter/keyword_fwd.hpp>
#include <boost/mpl/bool.hpp>
#include <boost/mpl/if.hpp>
#include <boost/mpl/eval_if.hpp>
#include <boost/type_traits/is_lvalue_reference.hpp>
#include <boost/type_traits/is_scalar.hpp>
#include <boost/type_traits/is_same.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename V, typename R, typename Tag>
    struct augment_predicate_check_consume_ref
      : ::mwboost::mpl::eval_if<
            ::mwboost::is_scalar<V>
          , ::mwboost::mpl::true_
          , ::mwboost::mpl::eval_if<
                ::mwboost::is_same<
                    typename Tag::qualifier
                  , ::mwboost::parameter::consume_reference
                >
              , ::mwboost::mpl::if_<
                    ::mwboost::is_lvalue_reference<R>
                  , ::mwboost::mpl::false_
                  , ::mwboost::mpl::true_
                >
              , mwboost::mpl::true_
            >
        >::type
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/type_traits/is_const.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename V, typename R, typename Tag>
    struct augment_predicate_check_out_ref
      : ::mwboost::mpl::eval_if<
            ::mwboost::is_same<
                typename Tag::qualifier
              , ::mwboost::parameter::out_reference
            >
          , ::mwboost::mpl::eval_if<
                ::mwboost::is_lvalue_reference<R>
              , ::mwboost::mpl::if_<
                    ::mwboost::is_const<V>
                  , ::mwboost::mpl::false_
                  , ::mwboost::mpl::true_
                >
              , ::mwboost::mpl::false_
            >
          , ::mwboost::mpl::true_
        >::type
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/lambda_tag.hpp>
#include <boost/mpl/apply_wrap.hpp>
#include <boost/mpl/lambda.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <
        typename Predicate
      , typename R
      , typename Tag
      , typename T
      , typename Args
    >
    class augment_predicate
    {
        typedef typename ::mwboost::mpl::lambda<
            Predicate
          , ::mwboost::parameter::aux::lambda_tag
        >::type _actual_predicate;

     public:
        typedef typename ::mwboost::mpl::eval_if<
            typename ::mwboost::mpl::if_<
                ::mwboost::parameter::aux
                ::augment_predicate_check_consume_ref<T,R,Tag>
              , ::mwboost::parameter::aux
                ::augment_predicate_check_out_ref<T,R,Tag>
              , ::mwboost::mpl::false_
            >::type
          , ::mwboost::mpl::apply_wrap2<_actual_predicate,T,Args>
          , ::mwboost::mpl::false_
        >::type type;
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/integral.hpp>
#include <boost/mp11/utility.hpp>
#include <type_traits>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename V, typename R, typename Tag>
    using augment_predicate_check_consume_ref_mp11 = ::mwboost::mp11::mp_if<
        ::std::is_scalar<V>
      , ::mwboost::mp11::mp_true
      , ::mwboost::mp11::mp_if<
            ::std::is_same<
                typename Tag::qualifier
              , ::mwboost::parameter::consume_reference
            >
          , ::mwboost::mp11::mp_if<
                ::std::is_lvalue_reference<R>
              , ::mwboost::mp11::mp_false
              , ::mwboost::mp11::mp_true
            >
          , mwboost::mp11::mp_true
        >
    >;

    template <typename V, typename R, typename Tag>
    using augment_predicate_check_out_ref_mp11 = ::mwboost::mp11::mp_if<
        ::std::is_same<
            typename Tag::qualifier
          , ::mwboost::parameter::out_reference
        >
      , ::mwboost::mp11::mp_if<
            ::std::is_lvalue_reference<R>
          , ::mwboost::mp11::mp_if<
                ::std::is_const<V>
              , ::mwboost::mp11::mp_false
              , ::mwboost::mp11::mp_true
            >
          , ::mwboost::mp11::mp_false
        >
      , ::mwboost::mp11::mp_true
    >;
}}} // namespace mwboost::parameter::aux

#include <boost/mp11/list.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <
        typename Predicate
      , typename R
      , typename Tag
      , typename T
      , typename Args
    >
    struct augment_predicate_mp11_impl
    {
        using type = ::mwboost::mp11::mp_if<
            ::mwboost::mp11::mp_if<
                ::mwboost::parameter::aux
                ::augment_predicate_check_consume_ref_mp11<T,R,Tag>
              , ::mwboost::parameter::aux
                ::augment_predicate_check_out_ref_mp11<T,R,Tag>
              , ::mwboost::mp11::mp_false
            >
          , ::mwboost::mp11
            ::mp_apply_q<Predicate,::mwboost::mp11::mp_list<T,Args> >
          , ::mwboost::mp11::mp_false
        >;
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/aux_/has_nested_template_fn.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <
        typename Predicate
      , typename R
      , typename Tag
      , typename T
      , typename Args
    >
    using augment_predicate_mp11 = ::mwboost::mp11::mp_if<
        ::mwboost::parameter::aux::has_nested_template_fn<Predicate>
      , ::mwboost::parameter::aux
        ::augment_predicate_mp11_impl<Predicate,R,Tag,T,Args>
      , ::mwboost::parameter::aux
        ::augment_predicate<Predicate,R,Tag,T,Args>
    >;
}}} // namespace mwboost::parameter::aux

#endif  // BOOST_PARAMETER_CAN_USE_MP11
#endif  // include guard

