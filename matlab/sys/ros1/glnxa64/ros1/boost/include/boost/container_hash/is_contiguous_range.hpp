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

// Copyright 2017, 2018 Peter Dimov.
// Distributed under the Boost Software License, Version 1.0.
// https://www.boost.org/LICENSE_1_0.txt

#ifndef BOOST_HASH_IS_CONTIGUOUS_RANGE_HPP_INCLUDED
#define BOOST_HASH_IS_CONTIGUOUS_RANGE_HPP_INCLUDED

#include <boost/container_hash/is_range.hpp>
#include <boost/type_traits/integral_constant.hpp>
#include <boost/config.hpp>
#include <boost/config/workaround.hpp>

#if !defined(BOOST_NO_CXX11_DECLTYPE) && !defined(BOOST_NO_SFINAE_EXPR) && !BOOST_WORKAROUND(BOOST_GCC, < 40700) && !BOOST_WORKAROUND(BOOST_MSVC, < 1910)

#include <boost/type_traits/is_integral.hpp>
#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/is_same.hpp>
#include <iterator>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
namespace hash_detail
{

template<class It, class T, class S>
    integral_constant< bool, is_same<typename std::iterator_traits<It>::value_type, T>::value && is_integral<S>::value >
        is_contiguous_range_check( It first, It last, T const*, T const*, S );

template<class T> decltype( is_contiguous_range_check( declval<T const&>().begin(), declval<T const&>().end(), declval<T const&>().data(), declval<T const&>().data() + declval<T const&>().size(), declval<T const&>().size() ) ) is_contiguous_range_( int );
template<class T> false_type is_contiguous_range_( ... );

template<class T> struct is_contiguous_range: decltype( hash_detail::is_contiguous_range_<T>( 0 ) )
{
};

} // namespace hash_detail

namespace container_hash
{

template<class T> struct is_contiguous_range: integral_constant< bool, is_range<T>::value && hash_detail::is_contiguous_range<T>::value >
{
};

} // namespace container_hash
} // namespace mwboost

#else // !defined(BOOST_NO_CXX11_DECLTYPE) && !defined(BOOST_NO_SFINAE_EXPR)

#include <cstddef>
#include <vector>
#include <string>
#if !defined(BOOST_NO_CXX11_HDR_ARRAY)
#include <array>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
namespace container_hash
{

template<class T> struct is_contiguous_range: false_type
{
};

template<class E, class T, class A> struct is_contiguous_range< std::basic_string<E, T, A> >: true_type
{
};

template<class E, class T, class A> struct is_contiguous_range< std::basic_string<E, T, A> const >: true_type
{
};

#if !defined(BOOST_NO_CXX11_HDR_ARRAY)

template<class T, std::size_t N> struct is_contiguous_range< std::array<T, N> >: true_type
{
};

template<class T, std::size_t N> struct is_contiguous_range< std::array<T, N> const >: true_type
{
};

#endif

} // namespace container_hash
} // namespace mwboost

#endif // !defined(BOOST_NO_CXX11_DECLTYPE) && !defined(BOOST_NO_SFINAE_EXPR)

#endif // #ifndef BOOST_HASH_IS_CONTIGUOUS_RANGE_HPP_INCLUDED

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
