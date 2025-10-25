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

// Copyright David Abrahams, Daniel Wallin 2003.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_PARAMETER_DEDUCED_HPP
#define BOOST_PARAMETER_DEDUCED_HPP

#include <boost/parameter/aux_/use_default.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter {

    // This metafunction can be used to describe the treatment of particular
    // named parameters for the purposes of overload elimination with SFINAE,
    // by placing specializations in the parameters<...> list.
    //
    // If a keyword k is specified with deduced<...>, that keyword
    // will be automatically deduced from the argument list.
    template <typename Tag>
    struct deduced
    {
        typedef Tag key_type;
    };
}}

#include <boost/parameter/config.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/integral.hpp>
#else
#include <boost/mpl/bool.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    template <typename T>
    struct is_deduced_aux
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
      : ::mwboost::mp11::mp_false
#else
      : ::mwboost::mpl::false_
#endif
    {
    };

    template <typename Tag>
    struct is_deduced_aux< ::mwboost::parameter::deduced<Tag> >
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
      : ::mwboost::mp11::mp_true
#else
      : ::mwboost::mpl::true_
#endif
    {
    };

    template <typename T>
    struct is_deduced0
      : ::mwboost::parameter::aux::is_deduced_aux<typename T::key_type>::type
    {
    };
}}} // namespace mwboost::parameter::aux

#include <boost/parameter/required.hpp>
#include <boost/parameter/optional.hpp>

#if defined(BOOST_PARAMETER_CAN_USE_MP11)
#include <boost/mp11/utility.hpp>
#else
#include <boost/mpl/if.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace parameter { namespace aux {

    //
    // tag_type, has_default, and predicate --
    //
    // These metafunctions accept a ParameterSpec and extract the
    // keyword tag, whether or not a default is supplied for the
    // parameter, and the predicate that the corresponding actual
    // argument type is required match.
    //
    // a ParameterSpec is a specialization of either keyword<...>,
    // required<...>, optional<...>
    //

    template <typename T>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
    using has_default = ::mwboost::mp11::mp_if<
        ::mwboost::parameter::aux::is_required<T>
      , ::mwboost::mp11::mp_false
      , ::mwboost::mp11::mp_true
    >;
#else
    struct has_default
      : ::mwboost::mpl::if_<
            ::mwboost::parameter::aux::is_required<T>
          , ::mwboost::mpl::false_
          , ::mwboost::mpl::true_
        >::type
    {
    };
#endif

    template <typename T>
#if defined(BOOST_PARAMETER_CAN_USE_MP11)
    using is_deduced = ::mwboost::mp11::mp_if<
        ::mwboost::mp11::mp_if<
            ::mwboost::parameter::aux::is_optional<T>
          , ::mwboost::mp11::mp_true
          , ::mwboost::parameter::aux::is_required<T>
        >
      , ::mwboost::parameter::aux::is_deduced0<T>
      , ::mwboost::mp11::mp_false
    >;
#else
    struct is_deduced
      : ::mwboost::mpl::if_<
            typename ::mwboost::mpl::if_<
                ::mwboost::parameter::aux::is_optional<T>
              , ::mwboost::mpl::true_
              , ::mwboost::parameter::aux::is_required<T>
            >::type
          , ::mwboost::parameter::aux::is_deduced0<T>
          , ::mwboost::mpl::false_
        >::type
    {
    };
#endif  // BOOST_PARAMETER_CAN_USE_MP11
}}} // namespace mwboost::parameter::aux

#endif  // include guard


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
