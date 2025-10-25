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

#ifndef BOOST_SMART_PTR_SHARED_ARRAY_HPP_INCLUDED
#define BOOST_SMART_PTR_SHARED_ARRAY_HPP_INCLUDED

//
//  shared_array.hpp
//
//  (C) Copyright Greg Colvin and Beman Dawes 1998, 1999.
//  Copyright (c) 2001, 2002, 2012 Peter Dimov
//
//  Distributed under the Boost Software License, Version 1.0. (See
//  accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)
//
//  See http://www.boost.org/libs/smart_ptr/ for documentation.
//

#include <boost/config.hpp>   // for broken compiler workarounds

#include <memory>             // TR1 cyclic inclusion fix

#include <boost/assert.hpp>
#include <boost/core/checked_delete.hpp>

#include <boost/smart_ptr/shared_ptr.hpp>
#include <boost/smart_ptr/detail/shared_count.hpp>
#include <boost/smart_ptr/detail/sp_nullptr_t.hpp>
#include <boost/smart_ptr/detail/sp_noexcept.hpp>
#include <boost/config/workaround.hpp>

#include <cstddef>            // for std::ptrdiff_t
#include <algorithm>          // for std::swap
#include <functional>         // for std::less

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

//
//  shared_array
//
//  shared_array extends shared_ptr to arrays.
//  The array pointed to is deleted when the last shared_array pointing to it
//  is destroyed or reset.
//

template<class T> class shared_array
{
private:

    // Borland 5.5.1 specific workarounds
    typedef checked_array_deleter<T> deleter;
    typedef shared_array<T> this_type;

public:

    typedef T element_type;

    shared_array() BOOST_SP_NOEXCEPT : px( 0 ), pn()
    {
    }

#if !defined( BOOST_NO_CXX11_NULLPTR )

    shared_array( mwboost::detail::sp_nullptr_t ) BOOST_SP_NOEXCEPT : px( 0 ), pn()
    {
    }

#endif

    template<class Y>
    explicit shared_array( Y * p ): px( p ), pn( p, checked_array_deleter<Y>() )
    {
        mwboost::detail::sp_assert_convertible< Y[], T[] >();
    }

    //
    // Requirements: D's copy constructor must not throw
    //
    // shared_array will release p by calling d(p)
    //

    template<class Y, class D> shared_array( Y * p, D d ): px( p ), pn( p, d )
    {
        mwboost::detail::sp_assert_convertible< Y[], T[] >();
    }

    // As above, but with allocator. A's copy constructor shall not throw.

    template<class Y, class D, class A> shared_array( Y * p, D d, A a ): px( p ), pn( p, d, a )
    {
        mwboost::detail::sp_assert_convertible< Y[], T[] >();
    }

//  generated copy constructor, destructor are fine...

#if !defined( BOOST_NO_CXX11_RVALUE_REFERENCES )

// ... except in C++0x, move disables the implicit copy

    shared_array( shared_array const & r ) BOOST_SP_NOEXCEPT : px( r.px ), pn( r.pn )
    {
    }

    shared_array( shared_array && r ) BOOST_SP_NOEXCEPT : px( r.px ), pn()
    {
        pn.swap( r.pn );
        r.px = 0;
    }

#endif

    // conversion

    template<class Y>
#if !defined( BOOST_SP_NO_SP_CONVERTIBLE )

    shared_array( shared_array<Y> const & r, typename mwboost::detail::sp_enable_if_convertible< Y[], T[] >::type = mwboost::detail::sp_empty() )

#else

    shared_array( shared_array<Y> const & r )

#endif
    BOOST_SP_NOEXCEPT : px( r.px ), pn( r.pn )
    {
        mwboost::detail::sp_assert_convertible< Y[], T[] >();
    }

    // aliasing

    template< class Y >
    shared_array( shared_array<Y> const & r, element_type * p ) BOOST_SP_NOEXCEPT : px( p ), pn( r.pn )
    {
    }

    // assignment

    shared_array & operator=( shared_array const & r ) BOOST_SP_NOEXCEPT
    {
        this_type( r ).swap( *this );
        return *this;
    }

#if !defined(BOOST_MSVC) || (BOOST_MSVC >= 1400)

    template<class Y>
    shared_array & operator=( shared_array<Y> const & r ) BOOST_SP_NOEXCEPT
    {
        this_type( r ).swap( *this );
        return *this;
    }

#endif

#if !defined( BOOST_NO_CXX11_RVALUE_REFERENCES )

    shared_array & operator=( shared_array && r ) BOOST_SP_NOEXCEPT
    {
        this_type( static_cast< shared_array && >( r ) ).swap( *this );
        return *this;
    }

    template<class Y>
    shared_array & operator=( shared_array<Y> && r ) BOOST_SP_NOEXCEPT
    {
        this_type( static_cast< shared_array<Y> && >( r ) ).swap( *this );
        return *this;
    }

#endif

    void reset() BOOST_SP_NOEXCEPT
    {
        this_type().swap( *this );
    }

    template<class Y> void reset( Y * p ) // Y must be complete
    {
        BOOST_ASSERT( p == 0 || p != px ); // catch self-reset errors
        this_type( p ).swap( *this );
    }

    template<class Y, class D> void reset( Y * p, D d )
    {
        this_type( p, d ).swap( *this );
    }

    template<class Y, class D, class A> void reset( Y * p, D d, A a )
    {
        this_type( p, d, a ).swap( *this );
    }

    template<class Y> void reset( shared_array<Y> const & r, element_type * p ) BOOST_SP_NOEXCEPT
    {
        this_type( r, p ).swap( *this );
    }

    T & operator[] (std::ptrdiff_t i) const BOOST_SP_NOEXCEPT_WITH_ASSERT
    {
        BOOST_ASSERT(px != 0);
        BOOST_ASSERT(i >= 0);
        return px[i];
    }
    
    T * get() const BOOST_SP_NOEXCEPT
    {
        return px;
    }

// implicit conversion to "bool"
#include <boost/smart_ptr/detail/operator_bool.hpp>

    bool unique() const BOOST_SP_NOEXCEPT
    {
        return pn.unique();
    }

    long use_count() const BOOST_SP_NOEXCEPT
    {
        return pn.use_count();
    }

    void swap(shared_array<T> & other) BOOST_SP_NOEXCEPT
    {
        std::swap(px, other.px);
        pn.swap(other.pn);
    }

    void * _internal_get_deleter( mwboost::detail::sp_typeinfo_ const & ti ) const BOOST_SP_NOEXCEPT
    {
        return pn.get_deleter( ti );
    }

private:

    template<class Y> friend class shared_array;

    T * px;                     // contained pointer
    detail::shared_count pn;    // reference counter

};  // shared_array

template<class T> inline bool operator==(shared_array<T> const & a, shared_array<T> const & b) BOOST_SP_NOEXCEPT
{
    return a.get() == b.get();
}

template<class T> inline bool operator!=(shared_array<T> const & a, shared_array<T> const & b) BOOST_SP_NOEXCEPT
{
    return a.get() != b.get();
}

#if !defined( BOOST_NO_CXX11_NULLPTR )

template<class T> inline bool operator==( shared_array<T> const & p, mwboost::detail::sp_nullptr_t ) BOOST_SP_NOEXCEPT
{
    return p.get() == 0;
}

template<class T> inline bool operator==( mwboost::detail::sp_nullptr_t, shared_array<T> const & p ) BOOST_SP_NOEXCEPT
{
    return p.get() == 0;
}

template<class T> inline bool operator!=( shared_array<T> const & p, mwboost::detail::sp_nullptr_t ) BOOST_SP_NOEXCEPT
{
    return p.get() != 0;
}

template<class T> inline bool operator!=( mwboost::detail::sp_nullptr_t, shared_array<T> const & p ) BOOST_SP_NOEXCEPT
{
    return p.get() != 0;
}

#endif

template<class T> inline bool operator<(shared_array<T> const & a, shared_array<T> const & b) BOOST_SP_NOEXCEPT
{
    return std::less<T*>()(a.get(), b.get());
}

template<class T> void swap(shared_array<T> & a, shared_array<T> & b) BOOST_SP_NOEXCEPT
{
    a.swap(b);
}

template< class D, class T > D * get_deleter( shared_array<T> const & p ) BOOST_SP_NOEXCEPT
{
    return static_cast< D * >( p._internal_get_deleter( BOOST_SP_TYPEID_(D) ) );
}

} // namespace mwboost

#endif  // #ifndef BOOST_SMART_PTR_SHARED_ARRAY_HPP_INCLUDED

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
