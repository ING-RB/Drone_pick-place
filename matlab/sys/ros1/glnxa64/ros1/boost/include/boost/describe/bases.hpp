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

#ifndef BOOST_DESCRIBE_BASES_HPP_INCLUDED
#define BOOST_DESCRIBE_BASES_HPP_INCLUDED

// Copyright 2020, 2021 Peter Dimov
// Distributed under the Boost Software License, Version 1.0.
// https://www.boost.org/LICENSE_1_0.txt

#include <boost/describe/modifiers.hpp>
#include <boost/describe/detail/void_t.hpp>
#include <boost/describe/detail/config.hpp>

#if defined(BOOST_DESCRIBE_CXX11)

#include <boost/mp11/algorithm.hpp>
#include <type_traits>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
namespace describe
{
namespace detail
{

template<class T> using _describe_bases = decltype( boost_base_descriptor_fn( static_cast<T**>(0) ) );

template<unsigned M> struct base_filter
{
    template<class T> using fn = mp11::mp_bool< ( M & mod_any_access & T::modifiers ) != 0 >;
};

template<class T, class En = void> struct has_describe_bases: std::false_type
{
};

template<class T> struct has_describe_bases<T, void_t<_describe_bases<T>>>: std::true_type
{
};

} // namespace detail

template<class T, unsigned M> using describe_bases = mp11::mp_copy_if_q<detail::_describe_bases<T>, detail::base_filter<M>>;

template<class T> using has_describe_bases = detail::has_describe_bases<T>;

} // namespace describe
} // namespace mwboost

#endif // !defined(BOOST_DESCRIBE_CXX11)

#endif // #ifndef BOOST_DESCRIBE_BASES_HPP_INCLUDED

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
