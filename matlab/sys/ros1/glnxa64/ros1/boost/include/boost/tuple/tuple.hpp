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

//  tuple.hpp - Boost Tuple Library --------------------------------------

// Copyright (C) 1999, 2000 Jaakko Jarvi (jaakko.jarvi@cs.utu.fi)
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org

// -----------------------------------------------------------------

#ifndef BOOST_TUPLE_HPP
#define BOOST_TUPLE_HPP

#if defined(__sgi) && defined(_COMPILER_VERSION) && _COMPILER_VERSION <= 730
// Work around a compiler bug.
// mwboost::python::tuple has to be seen by the compiler before the
// mwboost::tuple class template.
namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace python { class tuple; }}
#endif

#include <boost/config.hpp>
#include <boost/static_assert.hpp>

// other compilers
#include <boost/ref.hpp>
#include <boost/tuple/detail/tuple_basic.hpp>


namespace mwboost {} namespace boost = mwboost; namespace mwboost {

using tuples::tuple;
using tuples::make_tuple;
using tuples::tie;
#if !defined(BOOST_NO_USING_TEMPLATE)
using tuples::get;
#else
//
// The "using tuples::get" statement causes the
// Borland compiler to ICE, use forwarding
// functions instead:
//
template<int N, class HT, class TT>
inline typename tuples::access_traits<
                  typename tuples::element<N, tuples::cons<HT, TT> >::type
                >::non_const_type
get(tuples::cons<HT, TT>& c) {
  return tuples::get<N,HT,TT>(c);
}
// get function for const cons-lists, returns a const reference to
// the element. If the element is a reference, returns the reference
// as such (that is, can return a non-const reference)
template<int N, class HT, class TT>
inline typename tuples::access_traits<
                  typename tuples::element<N, tuples::cons<HT, TT> >::type
                >::const_type
get(const tuples::cons<HT, TT>& c) {
  return tuples::get<N,HT,TT>(c);
}

#endif // BOOST_NO_USING_TEMPLATE

} // end namespace mwboost

#if !defined(BOOST_NO_CXX11_HDR_TUPLE)

#include <tuple>
#include <cstddef>

namespace std
{

#if defined(BOOST_CLANG)
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wmismatched-tags"
#endif

// std::tuple_size

template<class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8, class T9, class T10>
    class tuple_size< mwboost::tuples::tuple<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> >:
        public mwboost::tuples::length< mwboost::tuples::tuple<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> >
{
};

template<class H, class T> class tuple_size< mwboost::tuples::cons<H, T> >:
    public mwboost::tuples::length< mwboost::tuples::cons<H, T> >
{
};

template<> class tuple_size< mwboost::tuples::null_type >:
    public mwboost::tuples::length< mwboost::tuples::null_type >
{
};

// std::tuple_element

template<std::size_t I, class T1, class T2, class T3, class T4, class T5, class T6, class T7, class T8, class T9, class T10>
    class tuple_element< I, mwboost::tuples::tuple<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> >:
        public mwboost::tuples::element< I, mwboost::tuples::tuple<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> >
{
};

template<std::size_t I, class H, class T> class tuple_element< I, mwboost::tuples::cons<H, T> >:
    public mwboost::tuples::element< I, mwboost::tuples::cons<H, T> >
{
};

#if defined(BOOST_CLANG)
# pragma clang diagnostic pop
#endif

} // namespace std

#endif // !defined(BOOST_NO_CXX11_HDR_TUPLE)

#endif // BOOST_TUPLE_HPP

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
