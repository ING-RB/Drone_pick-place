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

/*
Copyright 2019 Glen Joseph Fernandes
(glenjofe@gmail.com)

Distributed under the Boost Software License, Version 1.0.
(http://www.boost.org/LICENSE_1_0.txt)
*/
#ifndef BOOST_CORE_NOINIT_ADAPTOR_HPP
#define BOOST_CORE_NOINIT_ADAPTOR_HPP

#include <boost/core/allocator_access.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template<class A>
struct noinit_adaptor
    : A {
    typedef void _default_construct_destroy;

    template<class U>
    struct rebind {
        typedef noinit_adaptor<typename allocator_rebind<A, U>::type> other;
    };

    noinit_adaptor()
        : A() { }

#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
    template<class U>
    noinit_adaptor(U&& u) BOOST_NOEXCEPT
        : A(std::forward<U>(u)) { }
#else
    template<class U>
    noinit_adaptor(const U& u) BOOST_NOEXCEPT
        : A(u) { }

    template<class U>
    noinit_adaptor(U& u) BOOST_NOEXCEPT
        : A(u) { }
#endif

    template<class U>
    noinit_adaptor(const noinit_adaptor<U>& u) BOOST_NOEXCEPT
        : A(static_cast<const A&>(u)) { }

    template<class U>
    void construct(U* p) {
        ::new((void*)p) U;
    }

#if defined(BOOST_NO_CXX11_ALLOCATOR)
    template<class U, class V>
    void construct(U* p, const V& v) {
        ::new((void*)p) U(v);
    }
#endif

    template<class U>
    void destroy(U* p) {
        p->~U();
        (void)p;
    }
};

template<class T, class U>
inline bool
operator==(const noinit_adaptor<T>& lhs,
    const noinit_adaptor<U>& rhs) BOOST_NOEXCEPT
{
    return static_cast<const T&>(lhs) == static_cast<const U&>(rhs);
}

template<class T, class U>
inline bool
operator!=(const noinit_adaptor<T>& lhs,
    const noinit_adaptor<U>& rhs) BOOST_NOEXCEPT
{
    return !(lhs == rhs);
}

template<class A>
inline noinit_adaptor<A>
noinit_adapt(const A& a) BOOST_NOEXCEPT
{
    return noinit_adaptor<A>(a);
}

} /* boost */

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
