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
#ifndef BOOST_CORE_DEFAULT_ALLOCATOR_HPP
#define BOOST_CORE_DEFAULT_ALLOCATOR_HPP

#include <boost/config.hpp>
#include <new>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#if defined(BOOST_NO_EXCEPTIONS)
BOOST_NORETURN void throw_exception(const std::exception&);
#endif

namespace default_ {

template<bool V>
struct bool_constant {
    typedef bool value_type;
    typedef bool_constant type;

    static const bool value = V;

    operator bool() const BOOST_NOEXCEPT {
        return V;
    }

    bool operator()() const BOOST_NOEXCEPT {
        return V;
    }
};

template<bool V>
const bool bool_constant<V>::value;

template<class T>
struct add_reference {
    typedef T& type;
};

template<>
struct add_reference<void> {
    typedef void type;
};

template<>
struct add_reference<const void> {
    typedef const void type;
};

template<class T>
struct default_allocator {
    typedef T value_type;
    typedef T* pointer;
    typedef const T* const_pointer;
    typedef typename add_reference<T>::type reference;
    typedef typename add_reference<const T>::type const_reference;
    typedef std::size_t size_type;
    typedef std::ptrdiff_t difference_type;
    typedef bool_constant<true> propagate_on_container_move_assignment;
    typedef bool_constant<true> is_always_equal;

    template<class U>
    struct rebind {
        typedef default_allocator<U> other;
    };

#if !defined(BOOST_NO_CXX11_DEFAULTED_FUNCTIONS)
    default_allocator() = default;
#else
    BOOST_CONSTEXPR default_allocator() BOOST_NOEXCEPT { }
#endif

    template<class U>
    BOOST_CONSTEXPR default_allocator(const default_allocator<U>&)
        BOOST_NOEXCEPT { }

    BOOST_CONSTEXPR std::size_t max_size() const BOOST_NOEXCEPT {
        return static_cast<std::size_t>(-1) / (2 < sizeof(T) ? sizeof(T) : 2);
    }

#if !defined(BOOST_NO_EXCEPTIONS)
    T* allocate(std::size_t n) {
        if (n > max_size()) {
            throw std::bad_alloc();
        }
        return static_cast<T*>(::operator new(sizeof(T) * n));
    }

    void deallocate(T* p, std::size_t) {
        ::operator delete(p);
    }
#else
    T* allocate(std::size_t n) {
        if (n > max_size()) {
            mwboost::throw_exception(std::bad_alloc());
        }
        void* p = ::operator new(sizeof(T) * n, std::nothrow);
        if (!p) {
            mwboost::throw_exception(std::bad_alloc());
        }
        return static_cast<T*>(p);
    }

    void deallocate(T* p, std::size_t) {
        ::operator delete(p, std::nothrow);
    }
#endif

#if defined(BOOST_NO_CXX11_ALLOCATOR)
    T* allocate(std::size_t n, const void*) {
        return allocate(n);
    }
#endif

#if (defined(BOOST_LIBSTDCXX_VERSION) && BOOST_LIBSTDCXX_VERSION < 60000) || \
    defined(BOOST_NO_CXX11_ALLOCATOR)
    template<class U, class V>
    void construct(U* p, const V& v) {
        ::new(p) U(v);
    }

    template<class U>
    void destroy(U* p) {
        p->~U();
        (void)p;
    }
#endif
};

template<class T, class U>
BOOST_CONSTEXPR inline bool
operator==(const default_allocator<T>&,
    const default_allocator<U>&) BOOST_NOEXCEPT
{
    return true;
}

template<class T, class U>
BOOST_CONSTEXPR inline bool
operator!=(const default_allocator<T>&,
    const default_allocator<U>&) BOOST_NOEXCEPT
{
    return false;
}

} /* default_ */

using default_::default_allocator;

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
