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

/*=============================================================================
    Copyright (c) 2001-2011 Joel de Guzman
    Copyright (c) 2005 Eric Niebler

    Distributed under the Boost Software License, Version 1.0. (See accompanying 
    file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
==============================================================================*/
#if !defined(FUSION_CONS_ITERATOR_07172005_0849)
#define FUSION_CONS_ITERATOR_07172005_0849

#include <boost/fusion/support/config.hpp>
#include <boost/type_traits/add_const.hpp>
#include <boost/fusion/support/iterator_base.hpp>
#include <boost/fusion/container/list/detail/deref_impl.hpp>
#include <boost/fusion/container/list/detail/next_impl.hpp>
#include <boost/fusion/container/list/detail/value_of_impl.hpp>
#include <boost/fusion/container/list/detail/equal_to_impl.hpp>
#include <boost/fusion/container/list/list_fwd.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace fusion
{
    struct nil_;
    struct cons_iterator_tag;
    struct forward_traversal_tag;

    template <typename Cons>
    struct cons_iterator_identity;

#ifdef _MSC_VER
#  pragma warning(push)
#  pragma warning(disable: 4512) // assignment operator could not be generated.
#endif
    template <typename Cons = nil_>
    struct cons_iterator : iterator_base<cons_iterator<Cons> >
    {
        typedef cons_iterator_tag fusion_tag;
        typedef forward_traversal_tag category;
        typedef Cons cons_type;
        typedef cons_iterator_identity<
            typename add_const<Cons>::type> 
        identity;

        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit cons_iterator(cons_type& in_cons) BOOST_NOEXCEPT
            : cons(in_cons) {}

        cons_type& cons;
    };
#ifdef _MSC_VER
#  pragma warning(pop)
#endif

    struct nil_iterator : iterator_base<nil_iterator>
    {
        typedef forward_traversal_tag category;
        typedef cons_iterator_tag fusion_tag;
        typedef nil_ cons_type;
        typedef cons_iterator_identity<
            add_const<nil_>::type> 
        identity;

        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        nil_iterator() BOOST_NOEXCEPT {}
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit nil_iterator(nil_ const&) BOOST_NOEXCEPT {}
    };

    template <>
    struct cons_iterator<nil_> : nil_iterator 
    {
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        cons_iterator() BOOST_NOEXCEPT {}
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit cons_iterator(nil_ const&) BOOST_NOEXCEPT {}
    };

    template <>
    struct cons_iterator<nil_ const> : nil_iterator 
    {
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        cons_iterator() BOOST_NOEXCEPT {}
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit cons_iterator(nil_ const&) BOOST_NOEXCEPT {}
    };

    template <>
    struct cons_iterator<list<> > : nil_iterator 
    {
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        cons_iterator() BOOST_NOEXCEPT {}
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit cons_iterator(nil_ const&) BOOST_NOEXCEPT {}
    };

    template <>
    struct cons_iterator<list<> const> : nil_iterator 
    {
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        cons_iterator() BOOST_NOEXCEPT {}
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit cons_iterator(nil_ const&) BOOST_NOEXCEPT {}
    };
}}

#ifdef BOOST_FUSION_WORKAROUND_FOR_LWG_2408
namespace std
{
    template <typename Cons>
    struct iterator_traits< ::mwboost::fusion::cons_iterator<Cons> >
    { };
}
#endif

#endif

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
