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
Copyright 2021 Glen Joseph Fernandes
(glenjofe@gmail.com)

Distributed under the Boost Software License, Version 1.0.
(http://www.boost.org/LICENSE_1_0.txt)
*/
#ifndef BOOST_CORE_ALLOCATOR_TRAITS_HPP
#define BOOST_CORE_ALLOCATOR_TRAITS_HPP

#include <boost/core/allocator_access.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template<class A>
struct allocator_traits {
    typedef A allocator_type;

    typedef typename allocator_value_type<A>::type value_type;

    typedef typename allocator_pointer<A>::type pointer;

    typedef typename allocator_const_pointer<A>::type const_pointer;

    typedef typename allocator_void_pointer<A>::type void_pointer;

    typedef typename allocator_const_void_pointer<A>::type const_void_pointer;

    typedef typename allocator_difference_type<A>::type difference_type;

    typedef typename allocator_size_type<A>::type size_type;

    typedef typename allocator_propagate_on_container_copy_assignment<A>::type
        propagate_on_container_copy_assignment;

    typedef typename allocator_propagate_on_container_move_assignment<A>::type
        propagate_on_container_move_assignment;

    typedef typename allocator_propagate_on_container_swap<A>::type
        propagate_on_container_swap;

    typedef typename allocator_is_always_equal<A>::type is_always_equal;

#if !defined(BOOST_NO_CXX11_TEMPLATE_ALIASES)
    template<class T>
    using rebind_traits = allocator_traits<typename
        allocator_rebind<A, T>::type>;
#else
    template<class T>
    struct rebind_traits
        : allocator_traits<typename allocator_rebind<A, T>::type> { };
#endif

    static pointer allocate(A& a, size_type n) {
        return mwboost::allocator_allocate(a, n);
    }

    static pointer allocate(A& a, size_type n, const_void_pointer h) {
        return mwboost::allocator_allocate(a, n, h);
    }

    static void deallocate(A& a, pointer p, size_type n) {
        return mwboost::allocator_deallocate(a, p, n);
    }

    template<class T>
    static void construct(A& a, T* p) {
        mwboost::allocator_construct(a, p);
    }

#if !defined(BOOST_NO_CXX11_RVALUE_REFERENCES)
#if !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES)
    template<class T, class V, class... Args>
    static void construct(A& a, T* p, V&& v, Args&&... args) {
        mwboost::allocator_construct(a, p, std::forward<V>(v),
            std::forward<Args>(args)...);
    }
#else
    template<class T, class V>
    static void construct(A& a, T* p, V&& v) {
        mwboost::allocator_construct(a, p, std::forward<V>(v));
    }
#endif
#else
    template<class T, class V>
    static void construct(A& a, T* p, const V& v) {
        mwboost::allocator_construct(a, p, v);
    }

    template<class T, class V>
    static void construct(A& a, T* p, V& v) {
        mwboost::allocator_construct(a, p, v);
    }
#endif

    template<class T>
    static void destroy(A& a, T* p) {
        mwboost::allocator_destroy(a, p);
    }

    static size_type max_size(const A& a) BOOST_NOEXCEPT {
        return mwboost::allocator_max_size(a);
    }

    static A select_on_container_copy_construction(const A& a) {
        return mwboost::allocator_select_on_container_copy_construction(a);
    }
};

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
