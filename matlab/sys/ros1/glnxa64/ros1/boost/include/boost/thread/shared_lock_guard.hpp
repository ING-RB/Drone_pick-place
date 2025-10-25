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
// (C) Copyright 2012 Vicente J. Botet Escriba

#ifndef BOOST_THREAD_SHARED_LOCK_GUARD_HPP
#define BOOST_THREAD_SHARED_LOCK_GUARD_HPP
#include <boost/thread/detail/config.hpp>
//#include <boost/thread/locks.hpp>
#include <boost/thread/lock_options.hpp>
#include <boost/thread/detail/delete.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

    template<typename SharedMutex>
    class shared_lock_guard
    {
    private:
        SharedMutex& m;

    public:
        typedef SharedMutex mutex_type;
        BOOST_THREAD_NO_COPYABLE(shared_lock_guard)
        explicit shared_lock_guard(SharedMutex& m_):
            m(m_)
        {
            m.lock_shared();
        }
        shared_lock_guard(SharedMutex& m_,adopt_lock_t):
            m(m_)
        {}
        ~shared_lock_guard()
        {
            m.unlock_shared();
        }
    };

#ifdef BOOST_THREAD_NO_AUTO_DETECT_MUTEX_TYPES

    template<typename T>
    struct is_mutex_type<shared_lock_guard<T> >
    {
        BOOST_STATIC_CONSTANT(bool, value = true);
    };


#endif


}

#endif // header

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
