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

#ifndef BOOST_BIND_MEM_FN_HPP_INCLUDED
#define BOOST_BIND_MEM_FN_HPP_INCLUDED

// MS compatible compilers support #pragma once

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

//
//  mem_fn.hpp - a generalization of std::mem_fun[_ref]
//
//  Copyright (c) 2001, 2002 Peter Dimov and Multi Media Ltd.
//  Copyright (c) 2001 David Abrahams
//  Copyright (c) 2003-2005 Peter Dimov
//
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//
//  See http://www.boost.org/libs/bind/mem_fn.html for documentation.
//

#include <boost/config.hpp>
#include <boost/get_pointer.hpp>
#include <boost/detail/workaround.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

#if defined(BOOST_NO_VOID_RETURNS)

#define BOOST_MEM_FN_CLASS_F , class F
#define BOOST_MEM_FN_TYPEDEF(X)

namespace _mfi // mem_fun_impl
{

template<class V> struct mf
{

#define BOOST_MEM_FN_RETURN return

#define BOOST_MEM_FN_NAME(X) inner_##X
#define BOOST_MEM_FN_CC

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#if defined(BOOST_MEM_FN_ENABLE_CDECL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) inner_##X##_cdecl
#define BOOST_MEM_FN_CC __cdecl

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#if defined(BOOST_MEM_FN_ENABLE_STDCALL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) inner_##X##_stdcall
#define BOOST_MEM_FN_CC __stdcall

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#if defined(BOOST_MEM_FN_ENABLE_FASTCALL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) inner_##X##_fastcall
#define BOOST_MEM_FN_CC __fastcall

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#undef BOOST_MEM_FN_RETURN

}; // struct mf<V>

template<> struct mf<void>
{

#define BOOST_MEM_FN_RETURN

#define BOOST_MEM_FN_NAME(X) inner_##X
#define BOOST_MEM_FN_CC

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#if defined(BOOST_MEM_FN_ENABLE_CDECL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) inner_##X##_cdecl
#define BOOST_MEM_FN_CC __cdecl

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#ifdef BOOST_MEM_FN_ENABLE_STDCALL

#define BOOST_MEM_FN_NAME(X) inner_##X##_stdcall
#define BOOST_MEM_FN_CC __stdcall

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#ifdef BOOST_MEM_FN_ENABLE_FASTCALL

#define BOOST_MEM_FN_NAME(X) inner_##X##_fastcall
#define BOOST_MEM_FN_CC __fastcall

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#undef BOOST_MEM_FN_RETURN

}; // struct mf<void>

#undef BOOST_MEM_FN_CLASS_F
#undef BOOST_MEM_FN_TYPEDEF_F

#define BOOST_MEM_FN_NAME(X) X
#define BOOST_MEM_FN_NAME2(X) inner_##X
#define BOOST_MEM_FN_CC

#include <boost/bind/mem_fn_vw.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_NAME2
#undef BOOST_MEM_FN_CC

#if defined(BOOST_MEM_FN_ENABLE_CDECL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_cdecl
#define BOOST_MEM_FN_NAME2(X) inner_##X##_cdecl
#define BOOST_MEM_FN_CC __cdecl

#include <boost/bind/mem_fn_vw.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_NAME2
#undef BOOST_MEM_FN_CC

#endif

#ifdef BOOST_MEM_FN_ENABLE_STDCALL

#define BOOST_MEM_FN_NAME(X) X##_stdcall
#define BOOST_MEM_FN_NAME2(X) inner_##X##_stdcall
#define BOOST_MEM_FN_CC __stdcall

#include <boost/bind/mem_fn_vw.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_NAME2
#undef BOOST_MEM_FN_CC

#endif

#ifdef BOOST_MEM_FN_ENABLE_FASTCALL

#define BOOST_MEM_FN_NAME(X) X##_fastcall
#define BOOST_MEM_FN_NAME2(X) inner_##X##_fastcall
#define BOOST_MEM_FN_CC __fastcall

#include <boost/bind/mem_fn_vw.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_NAME2
#undef BOOST_MEM_FN_CC

#endif

} // namespace _mfi

#else // #ifdef BOOST_NO_VOID_RETURNS

#define BOOST_MEM_FN_CLASS_F
#define BOOST_MEM_FN_TYPEDEF(X) typedef X;

namespace _mfi
{

#define BOOST_MEM_FN_RETURN return

#define BOOST_MEM_FN_NAME(X) X
#define BOOST_MEM_FN_CC

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#if defined(BOOST_MEM_FN_ENABLE_CDECL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_cdecl
#define BOOST_MEM_FN_CC __cdecl

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#if defined(BOOST_MEM_FN_ENABLE_STDCALL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_stdcall
#define BOOST_MEM_FN_CC __stdcall

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#if defined(BOOST_MEM_FN_ENABLE_FASTCALL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_fastcall
#define BOOST_MEM_FN_CC __fastcall

#include <boost/bind/mem_fn_template.hpp>

#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NAME

#endif

#undef BOOST_MEM_FN_RETURN

} // namespace _mfi

#undef BOOST_MEM_FN_CLASS_F
#undef BOOST_MEM_FN_TYPEDEF

#endif // #ifdef BOOST_NO_VOID_RETURNS

#define BOOST_MEM_FN_NAME(X) X
#define BOOST_MEM_FN_CC
#define BOOST_MEM_FN_NOEXCEPT

#include <boost/bind/mem_fn_cc.hpp>

#if defined( __cpp_noexcept_function_type ) || defined( _NOEXCEPT_TYPES_SUPPORTED )
#  undef BOOST_MEM_FN_NOEXCEPT
#  define BOOST_MEM_FN_NOEXCEPT noexcept
#  include <boost/bind/mem_fn_cc.hpp>
#endif

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NOEXCEPT

#if defined(BOOST_MEM_FN_ENABLE_CDECL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_cdecl
#define BOOST_MEM_FN_CC __cdecl
#define BOOST_MEM_FN_NOEXCEPT

#include <boost/bind/mem_fn_cc.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NOEXCEPT

#endif

#if defined(BOOST_MEM_FN_ENABLE_STDCALL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_stdcall
#define BOOST_MEM_FN_CC __stdcall
#define BOOST_MEM_FN_NOEXCEPT

#include <boost/bind/mem_fn_cc.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NOEXCEPT

#endif

#if defined(BOOST_MEM_FN_ENABLE_FASTCALL) && !defined(_M_X64)

#define BOOST_MEM_FN_NAME(X) X##_fastcall
#define BOOST_MEM_FN_CC __fastcall
#define BOOST_MEM_FN_NOEXCEPT

#include <boost/bind/mem_fn_cc.hpp>

#undef BOOST_MEM_FN_NAME
#undef BOOST_MEM_FN_CC
#undef BOOST_MEM_FN_NOEXCEPT

#endif

// data member support

namespace _mfi
{

template<class R, class T> class dm
{
public:

    typedef R const & result_type;
    typedef T const * argument_type;

private:
    
    typedef R (T::*F);
    F f_;

    template<class U> R const & call(U & u, T const *) const
    {
        return (u.*f_);
    }

    template<class U> R const & call(U & u, void const *) const
    {
        return (get_pointer(u)->*f_);
    }

public:
    
    explicit dm(F f): f_(f) {}

    R & operator()(T * p) const
    {
        return (p->*f_);
    }

    R const & operator()(T const * p) const
    {
        return (p->*f_);
    }

    template<class U> R const & operator()(U const & u) const
    {
        return call(u, &u);
    }

#if !BOOST_WORKAROUND(BOOST_MSVC, <= 1300) && !BOOST_WORKAROUND(__MWERKS__, < 0x3200)

    R & operator()(T & t) const
    {
        return (t.*f_);
    }

    R const & operator()(T const & t) const
    {
        return (t.*f_);
    }

#endif

    bool operator==(dm const & rhs) const
    {
        return f_ == rhs.f_;
    }

    bool operator!=(dm const & rhs) const
    {
        return f_ != rhs.f_;
    }
};

} // namespace _mfi

template<class R, class T> _mfi::dm<R, T> mem_fn(R T::*f)
{
    return _mfi::dm<R, T>(f);
}

} // namespace mwboost

#endif // #ifndef BOOST_BIND_MEM_FN_HPP_INCLUDED

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
