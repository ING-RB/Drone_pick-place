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

#ifndef BOOST_PTHREAD_MUTEX_SCOPED_LOCK_HPP
#define BOOST_PTHREAD_MUTEX_SCOPED_LOCK_HPP
//  (C) Copyright 2007-8 Anthony Williams
//
//  Distributed under the Boost Software License, Version 1.0. (See
//  accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

#include <pthread.h>
#include <boost/assert.hpp>
#include <boost/thread/pthread/pthread_helpers.hpp>

#include <boost/config/abi_prefix.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
    namespace pthread
    {
        class pthread_mutex_scoped_lock
        {
            pthread_mutex_t* m;
            bool locked;
        public:
            explicit pthread_mutex_scoped_lock(pthread_mutex_t* m_) BOOST_NOEXCEPT:
                m(m_),locked(true)
            {
                BOOST_VERIFY(!posix::pthread_mutex_lock(m));
            }
            void unlock() BOOST_NOEXCEPT
            {
                BOOST_VERIFY(!posix::pthread_mutex_unlock(m));
                locked=false;
            }
            void unlock_if_locked() BOOST_NOEXCEPT
            {
              if(locked)
              {
                  unlock();
              }
            }
            ~pthread_mutex_scoped_lock() BOOST_NOEXCEPT
            {
                if(locked)
                {
                    unlock();
                }
            }

        };

        class pthread_mutex_scoped_unlock
        {
            pthread_mutex_t* m;
        public:
            explicit pthread_mutex_scoped_unlock(pthread_mutex_t* m_) BOOST_NOEXCEPT:
                m(m_)
            {
                BOOST_VERIFY(!posix::pthread_mutex_unlock(m));
            }
            ~pthread_mutex_scoped_unlock() BOOST_NOEXCEPT
            {
                BOOST_VERIFY(!posix::pthread_mutex_lock(m));
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
