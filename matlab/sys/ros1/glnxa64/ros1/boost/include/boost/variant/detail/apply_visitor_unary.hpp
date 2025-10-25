//-----------------------------------------------------------------------------
// boost variant/detail/apply_visitor_unary.hpp header file
// See http://www.boost.org for updates, documentation, and revision history.
//-----------------------------------------------------------------------------
//
// Copyright (c) 2002-2003 Eric Friedman
// Copyright (c) 2014-2022 Antony Polukhin
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_VARIANT_DETAIL_APPLY_VISITOR_UNARY_HPP
#define BOOST_VARIANT_DETAIL_APPLY_VISITOR_UNARY_HPP

#include <boost/config.hpp>
#include <boost/move/utility.hpp>

#if !defined(BOOST_NO_CXX14_DECLTYPE_AUTO) && !defined(BOOST_NO_CXX11_DECLTYPE_N3276)
#   include <boost/mpl/distance.hpp>
#   include <boost/mpl/advance.hpp>
#   include <boost/mpl/deref.hpp>
#   include <boost/mpl/size.hpp>
#   include <boost/utility/declval.hpp>
#   include <boost/core/enable_if.hpp>
#   include <boost/type_traits/copy_cv_ref.hpp>
#   include <boost/type_traits/remove_reference.hpp>
#   include <boost/variant/detail/has_result_type.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

//////////////////////////////////////////////////////////////////////////
// function template apply_visitor(visitor, visitable)
//
// Visits visitable with visitor.
//

//
// nonconst-visitor version:
//

#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
template <typename Visitor, typename Visitable>
inline typename Visitor::result_type
apply_visitor(Visitor& visitor, Visitable&& visitable)
{
    return ::mwboost::forward<Visitable>(visitable).apply_visitor(visitor);
}
#else
template <typename Visitor, typename Visitable>
inline typename Visitor::result_type
apply_visitor(Visitor& visitor, Visitable& visitable)
{
    return visitable.apply_visitor(visitor);
}
#endif

//
// const-visitor version:
//

#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
template <typename Visitor, typename Visitable>
inline typename Visitor::result_type
apply_visitor(const Visitor& visitor, Visitable&& visitable)
{
    return ::mwboost::forward<Visitable>(visitable).apply_visitor(visitor);
}
#else
template <typename Visitor, typename Visitable>
inline typename Visitor::result_type
apply_visitor(const Visitor& visitor, Visitable& visitable)
{
    return visitable.apply_visitor(visitor);
}
#endif


#if !defined(BOOST_NO_CXX14_DECLTYPE_AUTO) && !defined(BOOST_NO_CXX11_DECLTYPE_N3276)
#define BOOST_VARIANT_HAS_DECLTYPE_APPLY_VISITOR_RETURN_TYPE

// C++14
namespace detail { namespace variant {

// This class serves only metaprogramming purposes. none of its methods must be called at runtime!
template <class Visitor, class Variant>
struct result_multideduce1 {
    typedef typename remove_reference<Variant>::type::types types;
    typedef typename mwboost::mpl::begin<types>::type begin_it;
    typedef typename mwboost::mpl::advance<
        begin_it, mwboost::mpl::int_<mwboost::mpl::size<types>::type::value - 1>
    >::type                                         last_it;

    template <class It, class Dummy = void> // avoid explicit specialization in class scope
    struct deduce_impl {
        typedef typename mwboost::mpl::next<It>::type next_t;
        typedef typename mwboost::mpl::deref<It>::type value_t;
        typedef decltype(true ? mwboost::declval< Visitor& >()( mwboost::declval< copy_cv_ref_t< value_t, Variant > >() )
                              : mwboost::declval< typename deduce_impl<next_t>::type >()) type;
    };

    template <class Dummy>
    struct deduce_impl<last_it, Dummy> {
        typedef typename mwboost::mpl::deref<last_it>::type value_t;
        typedef decltype(mwboost::declval< Visitor& >()( mwboost::declval< copy_cv_ref_t< value_t, Variant > >() )) type;
    };

    typedef typename deduce_impl<begin_it>::type type;
};

template <class Visitor, class Variant>
struct result_wrapper1
{
    typedef typename result_multideduce1<Visitor, Variant>::type result_type;

    Visitor&& visitor_;
    explicit result_wrapper1(Visitor&& visitor) BOOST_NOEXCEPT
        : visitor_(::mwboost::forward<Visitor>(visitor))
    {}

    template <class T>
    result_type operator()(T&& val) const {
        return visitor_(::mwboost::forward<T>(val));
    }
};

}} // namespace detail::variant

template <typename Visitor, typename Visitable>
inline decltype(auto) apply_visitor(Visitor&& visitor, Visitable&& visitable,
    typename mwboost::disable_if<
        mwboost::detail::variant::has_result_type<Visitor>,
        bool
    >::type = true)
{
    mwboost::detail::variant::result_wrapper1<Visitor, Visitable> cpp14_vis(::mwboost::forward<Visitor>(visitor));
    return ::mwboost::forward<Visitable>(visitable).apply_visitor(cpp14_vis);
}

#endif // !defined(BOOST_NO_CXX14_DECLTYPE_AUTO) && !defined(BOOST_NO_CXX11_DECLTYPE_N3276)

} // namespace mwboost

#endif // BOOST_VARIANT_DETAIL_APPLY_VISITOR_UNARY_HPP
