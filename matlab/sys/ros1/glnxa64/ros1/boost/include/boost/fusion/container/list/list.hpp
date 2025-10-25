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
    Copyright (c) 2014-2015 Kohei Takahashi

    Distributed under the Boost Software License, Version 1.0. (See accompanying
    file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
==============================================================================*/
#ifndef FUSION_LIST_10262014_0537
#define FUSION_LIST_10262014_0537

#include <boost/fusion/support/config.hpp>
#include <boost/fusion/container/list/list_fwd.hpp>

///////////////////////////////////////////////////////////////////////////////
// Without variadics, we will use the PP version
///////////////////////////////////////////////////////////////////////////////
#if !defined(BOOST_FUSION_HAS_VARIADIC_LIST)
# include <boost/fusion/container/list/detail/cpp03/list.hpp>
#else

///////////////////////////////////////////////////////////////////////////////
// C++11 interface
///////////////////////////////////////////////////////////////////////////////
#include <utility>
#include <boost/fusion/container/list/detail/list_to_cons.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace fusion
{
    struct nil_;

    template <>
    struct list<>
        : detail::list_to_cons<>::type
    {
    private:
        typedef detail::list_to_cons<> list_to_cons;
        typedef list_to_cons::type inherited_type;

    public:
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        list()
            : inherited_type() {}

#if defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
        template <typename Sequence>
        BOOST_FUSION_GPU_ENABLED
        list(Sequence const& rhs)
            : inherited_type(rhs) {}

        template <typename Sequence>
        BOOST_CXX14_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        list&
        operator=(Sequence const& rhs)
        {
            inherited_type::operator=(rhs);
            return *this;
        }
#else
        template <typename Sequence>
        BOOST_FUSION_GPU_ENABLED
        list(Sequence&& rhs)
            : inherited_type(std::forward<Sequence>(rhs)) {}

        template <typename Sequence>
        BOOST_CXX14_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        list&
        operator=(Sequence&& rhs)
        {
            inherited_type::operator=(std::forward<Sequence>(rhs));
            return *this;
        }
#endif
    };

    template <typename ...T>
    struct list
        : detail::list_to_cons<T...>::type
    {
    private:
        typedef detail::list_to_cons<T...> list_to_cons;
        typedef typename list_to_cons::type inherited_type;

    public:
        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        list()
            : inherited_type() {}

#if defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
        template <typename Sequence>
        BOOST_FUSION_GPU_ENABLED
        list(Sequence const& rhs)
            : inherited_type(rhs) {}
#else
        template <typename Sequence>
        BOOST_FUSION_GPU_ENABLED
        list(Sequence&& rhs)
            : inherited_type(std::forward<Sequence>(rhs)) {}
#endif

        BOOST_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        explicit
        list(typename detail::call_param<T>::type ...args)
            : inherited_type(list_to_cons::call(args...)) {}

#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
        template <typename Sequence>
        BOOST_CXX14_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        list&
        operator=(Sequence const& rhs)
        {
            inherited_type::operator=(rhs);
            return *this;
        }
#else
        template <typename Sequence>
        BOOST_CXX14_CONSTEXPR BOOST_FUSION_GPU_ENABLED
        list&
        operator=(Sequence&& rhs)
        {
            inherited_type::operator=(std::forward<Sequence>(rhs));
            return *this;
        }
#endif
    };
}}

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
