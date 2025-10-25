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

// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
// (C) Copyright 2008 Anthony Williams
#ifndef THREAD_HEAP_ALLOC_PTHREAD_HPP
#define THREAD_HEAP_ALLOC_PTHREAD_HPP

#include <boost/config/abi_prefix.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
    namespace detail
    {
        template<typename T>
        inline T* heap_new()
        {
            return new T();
        }
#if defined(BOOST_THREAD_PROVIDES_VARIADIC_THREAD) && ! defined (BOOST_NO_CXX11_RVALUE_REFERENCES)
        template<typename T,typename... Args>
        inline T* heap_new(Args&&... args)
        {
            return new T(static_cast<Args&&>(args)...);
        }
#elif ! defined BOOST_NO_CXX11_RVALUE_REFERENCES
        template<typename T,typename A1>
        inline T* heap_new(A1&& a1)
        {
            return new T(static_cast<A1&&>(a1));
        }
        template<typename T,typename A1,typename A2>
        inline T* heap_new(A1&& a1,A2&& a2)
        {
            return new T(static_cast<A1&&>(a1),static_cast<A2&&>(a2));
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1&& a1,A2&& a2,A3&& a3)
        {
            return new T(static_cast<A1&&>(a1),static_cast<A2&&>(a2),
                         static_cast<A3&&>(a3));
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1&& a1,A2&& a2,A3&& a3,A4&& a4)
        {
            return new T(static_cast<A1&&>(a1),static_cast<A2&&>(a2),
                         static_cast<A3&&>(a3),static_cast<A4&&>(a4));
        }
#else
        template<typename T,typename A1>
        inline T* heap_new_impl(A1 a1)
        {
            return new T(a1);
        }
        template<typename T,typename A1,typename A2>
        inline T* heap_new_impl(A1 a1,A2 a2)
        {
            return new T(a1,a2);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3)
        {
            return new T(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3,A4 a4)
        {
            return new T(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4,typename A5>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3,A4 a4,A5 a5)
        {
            return new T(a1,a2,a3,a4,a5);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4,typename A5,typename A6>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3,A4 a4,A5 a5,A6 a6)
        {
            return new T(a1,a2,a3,a4,a5,a6);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4,typename A5,typename A6,typename A7>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3,A4 a4,A5 a5,A6 a6,A7 a7)
        {
            return new T(a1,a2,a3,a4,a5,a6,a7);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4,typename A5,typename A6,typename A7,typename A8>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3,A4 a4,A5 a5,A6 a6,A7 a7,A8 a8)
        {
            return new T(a1,a2,a3,a4,a5,a6,a7,a8);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4,typename A5,typename A6,typename A7,typename A8,typename A9>
        inline T* heap_new_impl(A1 a1,A2 a2,A3 a3,A4 a4,A5 a5,A6 a6,A7 a7,A8 a8,A9 a9)
        {
            return new T(a1,a2,a3,a4,a5,a6,a7,a8,a9);
        }

        template<typename T,typename A1>
        inline T* heap_new(A1 const& a1)
        {
            return heap_new_impl<T,A1 const&>(a1);
        }
        template<typename T,typename A1>
        inline T* heap_new(A1& a1)
        {
            return heap_new_impl<T,A1&>(a1);
        }

        template<typename T,typename A1,typename A2>
        inline T* heap_new(A1 const& a1,A2 const& a2)
        {
            return heap_new_impl<T,A1 const&,A2 const&>(a1,a2);
        }
        template<typename T,typename A1,typename A2>
        inline T* heap_new(A1& a1,A2 const& a2)
        {
            return heap_new_impl<T,A1&,A2 const&>(a1,a2);
        }
        template<typename T,typename A1,typename A2>
        inline T* heap_new(A1 const& a1,A2& a2)
        {
            return heap_new_impl<T,A1 const&,A2&>(a1,a2);
        }
        template<typename T,typename A1,typename A2>
        inline T* heap_new(A1& a1,A2& a2)
        {
            return heap_new_impl<T,A1&,A2&>(a1,a2);
        }

        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1 const& a1,A2 const& a2,A3 const& a3)
        {
            return heap_new_impl<T,A1 const&,A2 const&,A3 const&>(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1& a1,A2 const& a2,A3 const& a3)
        {
            return heap_new_impl<T,A1&,A2 const&,A3 const&>(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1 const& a1,A2& a2,A3 const& a3)
        {
            return heap_new_impl<T,A1 const&,A2&,A3 const&>(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1& a1,A2& a2,A3 const& a3)
        {
            return heap_new_impl<T,A1&,A2&,A3 const&>(a1,a2,a3);
        }

        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1 const& a1,A2 const& a2,A3& a3)
        {
            return heap_new_impl<T,A1 const&,A2 const&,A3&>(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1& a1,A2 const& a2,A3& a3)
        {
            return heap_new_impl<T,A1&,A2 const&,A3&>(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1 const& a1,A2& a2,A3& a3)
        {
            return heap_new_impl<T,A1 const&,A2&,A3&>(a1,a2,a3);
        }
        template<typename T,typename A1,typename A2,typename A3>
        inline T* heap_new(A1& a1,A2& a2,A3& a3)
        {
            return heap_new_impl<T,A1&,A2&,A3&>(a1,a2,a3);
        }

        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2 const& a2,A3 const& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1 const&,A2 const&,A3 const&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2 const& a2,A3 const& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1&,A2 const&,A3 const&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2& a2,A3 const& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1 const&,A2&,A3 const&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2& a2,A3 const& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1&,A2&,A3 const&,A4 const&>(a1,a2,a3,a4);
        }

        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2 const& a2,A3& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1 const&,A2 const&,A3&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2 const& a2,A3& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1&,A2 const&,A3&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2& a2,A3& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1 const&,A2&,A3&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2& a2,A3& a3,A4 const& a4)
        {
            return heap_new_impl<T,A1&,A2&,A3&,A4 const&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2 const& a2,A3 const& a3,A4& a4)
        {
            return heap_new_impl<T,A1 const&,A2 const&,A3 const&,A4&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2 const& a2,A3 const& a3,A4& a4)
        {
            return heap_new_impl<T,A1&,A2 const&,A3 const&,A4&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2& a2,A3 const& a3,A4& a4)
        {
            return heap_new_impl<T,A1 const&,A2&,A3 const&,A4&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2& a2,A3 const& a3,A4& a4)
        {
            return heap_new_impl<T,A1&,A2&,A3 const&,A4&>(a1,a2,a3,a4);
        }

        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2 const& a2,A3& a3,A4& a4)
        {
            return heap_new_impl<T,A1 const&,A2 const&,A3&,A4&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2 const& a2,A3& a3,A4& a4)
        {
            return heap_new_impl<T,A1&,A2 const&,A3&,A4&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1 const& a1,A2& a2,A3& a3,A4& a4)
        {
            return heap_new_impl<T,A1 const&,A2&,A3&,A4&>(a1,a2,a3,a4);
        }
        template<typename T,typename A1,typename A2,typename A3,typename A4>
        inline T* heap_new(A1& a1,A2& a2,A3& a3,A4& a4)
        {
            return heap_new_impl<T,A1&,A2&,A3&,A4&>(a1,a2,a3,a4);
        }

#endif
        template<typename T>
        inline void heap_delete(T* data)
        {
            delete data;
        }

        template<typename T>
        struct do_heap_delete
        {
            void operator()(T* data) const
            {
                detail::heap_delete(data);
            }
        };
    }
}

#include <boost/config/abi_suffix.hpp>

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
