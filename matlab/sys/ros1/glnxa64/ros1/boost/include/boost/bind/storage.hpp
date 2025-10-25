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

#ifndef BOOST_BIND_STORAGE_HPP_INCLUDED
#define BOOST_BIND_STORAGE_HPP_INCLUDED

// MS compatible compilers support #pragma once

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

//
//  bind/storage.hpp
//
//  boost/bind.hpp support header, optimized storage
//
//  Copyright (c) 2006 Peter Dimov
//
//  Distributed under the Boost Software License, Version 1.0.
//  See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt
//
//  See http://www.boost.org/libs/bind/bind.html for documentation.
//

#include <boost/config.hpp>
#include <boost/bind/arg.hpp>

#ifdef BOOST_MSVC
# pragma warning(push)
# pragma warning(disable: 4512) // assignment operator could not be generated
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

namespace _bi
{

// 1

template<class A1> struct storage1
{
    explicit storage1( A1 a1 ): a1_( a1 ) {}

    template<class V> void accept(V & v) const
    {
        BOOST_BIND_VISIT_EACH(v, a1_, 0);
    }

    A1 a1_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION ) && !defined( BOOST_BORLANDC )

template<int I> struct storage1< mwboost::arg<I> >
{
    explicit storage1( mwboost::arg<I> ) {}

    template<class V> void accept(V &) const { }

    static mwboost::arg<I> a1_() { return mwboost::arg<I>(); }
};

template<int I> struct storage1< mwboost::arg<I> (*) () >
{
    explicit storage1( mwboost::arg<I> (*) () ) {}

    template<class V> void accept(V &) const { }

    static mwboost::arg<I> a1_() { return mwboost::arg<I>(); }
};

#endif

// 2

template<class A1, class A2> struct storage2: public storage1<A1>
{
    typedef storage1<A1> inherited;

    storage2( A1 a1, A2 a2 ): storage1<A1>( a1 ), a2_( a2 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a2_, 0);
    }

    A2 a2_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, int I> struct storage2< A1, mwboost::arg<I> >: public storage1<A1>
{
    typedef storage1<A1> inherited;

    storage2( A1 a1, mwboost::arg<I> ): storage1<A1>( a1 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a2_() { return mwboost::arg<I>(); }
};

template<class A1, int I> struct storage2< A1, mwboost::arg<I> (*) () >: public storage1<A1>
{
    typedef storage1<A1> inherited;

    storage2( A1 a1, mwboost::arg<I> (*) () ): storage1<A1>( a1 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a2_() { return mwboost::arg<I>(); }
};

#endif

// 3

template<class A1, class A2, class A3> struct storage3: public storage2< A1, A2 >
{
    typedef storage2<A1, A2> inherited;

    storage3( A1 a1, A2 a2, A3 a3 ): storage2<A1, A2>( a1, a2 ), a3_( a3 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a3_, 0);
    }

    A3 a3_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, int I> struct storage3< A1, A2, mwboost::arg<I> >: public storage2< A1, A2 >
{
    typedef storage2<A1, A2> inherited;

    storage3( A1 a1, A2 a2, mwboost::arg<I> ): storage2<A1, A2>( a1, a2 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a3_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, int I> struct storage3< A1, A2, mwboost::arg<I> (*) () >: public storage2< A1, A2 >
{
    typedef storage2<A1, A2> inherited;

    storage3( A1 a1, A2 a2, mwboost::arg<I> (*) () ): storage2<A1, A2>( a1, a2 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a3_() { return mwboost::arg<I>(); }
};

#endif

// 4

template<class A1, class A2, class A3, class A4> struct storage4: public storage3< A1, A2, A3 >
{
    typedef storage3<A1, A2, A3> inherited;

    storage4( A1 a1, A2 a2, A3 a3, A4 a4 ): storage3<A1, A2, A3>( a1, a2, a3 ), a4_( a4 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a4_, 0);
    }

    A4 a4_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, class A3, int I> struct storage4< A1, A2, A3, mwboost::arg<I> >: public storage3< A1, A2, A3 >
{
    typedef storage3<A1, A2, A3> inherited;

    storage4( A1 a1, A2 a2, A3 a3, mwboost::arg<I> ): storage3<A1, A2, A3>( a1, a2, a3 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a4_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, class A3, int I> struct storage4< A1, A2, A3, mwboost::arg<I> (*) () >: public storage3< A1, A2, A3 >
{
    typedef storage3<A1, A2, A3> inherited;

    storage4( A1 a1, A2 a2, A3 a3, mwboost::arg<I> (*) () ): storage3<A1, A2, A3>( a1, a2, a3 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a4_() { return mwboost::arg<I>(); }
};

#endif

// 5

template<class A1, class A2, class A3, class A4, class A5> struct storage5: public storage4< A1, A2, A3, A4 >
{
    typedef storage4<A1, A2, A3, A4> inherited;

    storage5( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5 ): storage4<A1, A2, A3, A4>( a1, a2, a3, a4 ), a5_( a5 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a5_, 0);
    }

    A5 a5_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, class A3, class A4, int I> struct storage5< A1, A2, A3, A4, mwboost::arg<I> >: public storage4< A1, A2, A3, A4 >
{
    typedef storage4<A1, A2, A3, A4> inherited;

    storage5( A1 a1, A2 a2, A3 a3, A4 a4, mwboost::arg<I> ): storage4<A1, A2, A3, A4>( a1, a2, a3, a4 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a5_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, class A3, class A4, int I> struct storage5< A1, A2, A3, A4, mwboost::arg<I> (*) () >: public storage4< A1, A2, A3, A4 >
{
    typedef storage4<A1, A2, A3, A4> inherited;

    storage5( A1 a1, A2 a2, A3 a3, A4 a4, mwboost::arg<I> (*) () ): storage4<A1, A2, A3, A4>( a1, a2, a3, a4 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a5_() { return mwboost::arg<I>(); }
};

#endif

// 6

template<class A1, class A2, class A3, class A4, class A5, class A6> struct storage6: public storage5< A1, A2, A3, A4, A5 >
{
    typedef storage5<A1, A2, A3, A4, A5> inherited;

    storage6( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6 ): storage5<A1, A2, A3, A4, A5>( a1, a2, a3, a4, a5 ), a6_( a6 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a6_, 0);
    }

    A6 a6_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, class A3, class A4, class A5, int I> struct storage6< A1, A2, A3, A4, A5, mwboost::arg<I> >: public storage5< A1, A2, A3, A4, A5 >
{
    typedef storage5<A1, A2, A3, A4, A5> inherited;

    storage6( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, mwboost::arg<I> ): storage5<A1, A2, A3, A4, A5>( a1, a2, a3, a4, a5 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a6_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, class A3, class A4, class A5, int I> struct storage6< A1, A2, A3, A4, A5, mwboost::arg<I> (*) () >: public storage5< A1, A2, A3, A4, A5 >
{
    typedef storage5<A1, A2, A3, A4, A5> inherited;

    storage6( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, mwboost::arg<I> (*) () ): storage5<A1, A2, A3, A4, A5>( a1, a2, a3, a4, a5 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a6_() { return mwboost::arg<I>(); }
};

#endif

// 7

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7> struct storage7: public storage6< A1, A2, A3, A4, A5, A6 >
{
    typedef storage6<A1, A2, A3, A4, A5, A6> inherited;

    storage7( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7 ): storage6<A1, A2, A3, A4, A5, A6>( a1, a2, a3, a4, a5, a6 ), a7_( a7 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a7_, 0);
    }

    A7 a7_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, class A3, class A4, class A5, class A6, int I> struct storage7< A1, A2, A3, A4, A5, A6, mwboost::arg<I> >: public storage6< A1, A2, A3, A4, A5, A6 >
{
    typedef storage6<A1, A2, A3, A4, A5, A6> inherited;

    storage7( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, mwboost::arg<I> ): storage6<A1, A2, A3, A4, A5, A6>( a1, a2, a3, a4, a5, a6 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a7_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, class A3, class A4, class A5, class A6, int I> struct storage7< A1, A2, A3, A4, A5, A6, mwboost::arg<I> (*) () >: public storage6< A1, A2, A3, A4, A5, A6 >
{
    typedef storage6<A1, A2, A3, A4, A5, A6> inherited;

    storage7( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, mwboost::arg<I> (*) () ): storage6<A1, A2, A3, A4, A5, A6>( a1, a2, a3, a4, a5, a6 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a7_() { return mwboost::arg<I>(); }
};

#endif

// 8

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7, class A8> struct storage8: public storage7< A1, A2, A3, A4, A5, A6, A7 >
{
    typedef storage7<A1, A2, A3, A4, A5, A6, A7> inherited;

    storage8( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7, A8 a8 ): storage7<A1, A2, A3, A4, A5, A6, A7>( a1, a2, a3, a4, a5, a6, a7 ), a8_( a8 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a8_, 0);
    }

    A8 a8_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7, int I> struct storage8< A1, A2, A3, A4, A5, A6, A7, mwboost::arg<I> >: public storage7< A1, A2, A3, A4, A5, A6, A7 >
{
    typedef storage7<A1, A2, A3, A4, A5, A6, A7> inherited;

    storage8( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7, mwboost::arg<I> ): storage7<A1, A2, A3, A4, A5, A6, A7>( a1, a2, a3, a4, a5, a6, a7 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a8_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7, int I> struct storage8< A1, A2, A3, A4, A5, A6, A7, mwboost::arg<I> (*) () >: public storage7< A1, A2, A3, A4, A5, A6, A7 >
{
    typedef storage7<A1, A2, A3, A4, A5, A6, A7> inherited;

    storage8( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7, mwboost::arg<I> (*) () ): storage7<A1, A2, A3, A4, A5, A6, A7>( a1, a2, a3, a4, a5, a6, a7 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a8_() { return mwboost::arg<I>(); }
};

#endif

// 9

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7, class A8, class A9> struct storage9: public storage8< A1, A2, A3, A4, A5, A6, A7, A8 >
{
    typedef storage8<A1, A2, A3, A4, A5, A6, A7, A8> inherited;

    storage9( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7, A8 a8, A9 a9 ): storage8<A1, A2, A3, A4, A5, A6, A7, A8>( a1, a2, a3, a4, a5, a6, a7, a8 ), a9_( a9 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
        BOOST_BIND_VISIT_EACH(v, a9_, 0);
    }

    A9 a9_;
};

#if !defined( BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION )

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7, class A8, int I> struct storage9< A1, A2, A3, A4, A5, A6, A7, A8, mwboost::arg<I> >: public storage8< A1, A2, A3, A4, A5, A6, A7, A8 >
{
    typedef storage8<A1, A2, A3, A4, A5, A6, A7, A8> inherited;

    storage9( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7, A8 a8, mwboost::arg<I> ): storage8<A1, A2, A3, A4, A5, A6, A7, A8>( a1, a2, a3, a4, a5, a6, a7, a8 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a9_() { return mwboost::arg<I>(); }
};

template<class A1, class A2, class A3, class A4, class A5, class A6, class A7, class A8, int I> struct storage9< A1, A2, A3, A4, A5, A6, A7, A8, mwboost::arg<I> (*) () >: public storage8< A1, A2, A3, A4, A5, A6, A7, A8 >
{
    typedef storage8<A1, A2, A3, A4, A5, A6, A7, A8> inherited;

    storage9( A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6, A7 a7, A8 a8, mwboost::arg<I> (*) () ): storage8<A1, A2, A3, A4, A5, A6, A7, A8>( a1, a2, a3, a4, a5, a6, a7, a8 ) {}

    template<class V> void accept(V & v) const
    {
        inherited::accept(v);
    }

    static mwboost::arg<I> a9_() { return mwboost::arg<I>(); }
};

#endif

} // namespace _bi

} // namespace mwboost

#ifdef BOOST_MSVC
# pragma warning(default: 4512) // assignment operator could not be generated
# pragma warning(pop)
#endif

#endif // #ifndef BOOST_BIND_STORAGE_HPP_INCLUDED

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
