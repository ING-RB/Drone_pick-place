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

#ifndef BOOST_THREAD_PTHREAD_RECURSIVE_MUTEX_HPP
#define BOOST_THREAD_PTHREAD_RECURSIVE_MUTEX_HPP
// (C) Copyright 2007-8 Anthony Williams
// (C) Copyright 2011-2012 Vicente J. Botet Escriba
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#include <pthread.h>
#include <boost/throw_exception.hpp>
#include <boost/thread/exceptions.hpp>
#if defined BOOST_THREAD_PROVIDES_NESTED_LOCKS
#include <boost/thread/lock_types.hpp>
#endif
#include <boost/thread/thread_time.hpp>
#include <boost/assert.hpp>
#ifndef _WIN32
#include <unistd.h>
#endif
#include <boost/date_time/posix_time/conversion.hpp>
#include <errno.h>
#include <boost/thread/detail/platform_time.hpp>
#include <boost/thread/pthread/pthread_mutex_scoped_lock.hpp>
#include <boost/thread/pthread/pthread_helpers.hpp>
#ifdef BOOST_THREAD_USES_CHRONO
#include <boost/chrono/system_clocks.hpp>
#include <boost/chrono/ceil.hpp>
#endif
#include <boost/thread/detail/delete.hpp>


#if  defined BOOST_HAS_PTHREAD_MUTEXATTR_SETTYPE \
 ||  defined __ANDROID__
#define BOOST_THREAD_HAS_PTHREAD_MUTEXATTR_SETTYPE
#endif

#if defined BOOST_THREAD_HAS_PTHREAD_MUTEXATTR_SETTYPE && defined BOOST_THREAD_USES_PTHREAD_TIMEDLOCK
#define BOOST_USE_PTHREAD_RECURSIVE_TIMEDLOCK
#endif

#include <boost/config/abi_prefix.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
    class recursive_mutex
    {
    private:
        pthread_mutex_t m;
#ifndef BOOST_THREAD_HAS_PTHREAD_MUTEXATTR_SETTYPE
        pthread_cond_t cond;
        bool is_locked;
        pthread_t owner;
        unsigned count;
#endif
    public:
        BOOST_THREAD_NO_COPYABLE(recursive_mutex)
        recursive_mutex()
        {
#ifdef BOOST_THREAD_HAS_PTHREAD_MUTEXATTR_SETTYPE
            pthread_mutexattr_t attr;

            int const init_attr_res=pthread_mutexattr_init(&attr);
            if(init_attr_res)
            {
                mwboost::throw_exception(thread_resource_error(init_attr_res, "mwboost:: recursive_mutex constructor failed in pthread_mutexattr_init"));
            }
            int const set_attr_res=pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
            if(set_attr_res)
            {
                BOOST_VERIFY(!pthread_mutexattr_destroy(&attr));
                mwboost::throw_exception(thread_resource_error(set_attr_res, "mwboost:: recursive_mutex constructor failed in pthread_mutexattr_settype"));
            }

            int const res=posix::pthread_mutex_init(&m,&attr);
            if(res)
            {
                BOOST_VERIFY(!pthread_mutexattr_destroy(&attr));
                mwboost::throw_exception(thread_resource_error(res, "mwboost:: recursive_mutex constructor failed in pthread_mutex_init"));
            }
            BOOST_VERIFY(!pthread_mutexattr_destroy(&attr));
#else
            int const res=posix::pthread_mutex_init(&m);
            if(res)
            {
                mwboost::throw_exception(thread_resource_error(res, "mwboost:: recursive_mutex constructor failed in pthread_mutex_init"));
            }
            int const res2=posix::pthread_cond_init(&cond);
            if(res2)
            {
                BOOST_VERIFY(!posix::pthread_mutex_destroy(&m));
                mwboost::throw_exception(thread_resource_error(res2, "mwboost:: recursive_mutex constructor failed in pthread_cond_init"));
            }
            is_locked=false;
            count=0;
#endif
        }
        ~recursive_mutex()
        {
            BOOST_VERIFY(!posix::pthread_mutex_destroy(&m));
#ifndef BOOST_THREAD_HAS_PTHREAD_MUTEXATTR_SETTYPE
            BOOST_VERIFY(!posix::pthread_cond_destroy(&cond));
#endif
        }

#ifdef BOOST_THREAD_HAS_PTHREAD_MUTEXATTR_SETTYPE
        void lock()
        {
            BOOST_VERIFY(!posix::pthread_mutex_lock(&m));
        }

        void unlock()
        {
            BOOST_VERIFY(!posix::pthread_mutex_unlock(&m));
        }

        bool try_lock() BOOST_NOEXCEPT
        {
            int const res=posix::pthread_mutex_trylock(&m);
            BOOST_ASSERT(!res || res==EBUSY);
            return !res;
        }
#define BOOST_THREAD_DEFINES_RECURSIVE_MUTEX_NATIVE_HANDLE
        typedef pthread_mutex_t* native_handle_type;
        native_handle_type native_handle()
        {
            return &m;
        }

#else
        void lock()
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(is_locked && pthread_equal(owner,pthread_self()))
            {
                ++count;
                return;
            }

            while(is_locked)
            {
                BOOST_VERIFY(!posix::pthread_cond_wait(&cond,&m));
            }
            is_locked=true;
            ++count;
            owner=pthread_self();
        }

        void unlock()
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(!--count)
            {
                is_locked=false;
            }
            BOOST_VERIFY(!posix::pthread_cond_signal(&cond));
        }

        bool try_lock()
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(is_locked && !pthread_equal(owner,pthread_self()))
            {
                return false;
            }
            is_locked=true;
            ++count;
            owner=pthread_self();
            return true;
        }

#endif

#if defined BOOST_THREAD_PROVIDES_NESTED_LOCKS
        typedef unique_lock<recursive_mutex> scoped_lock;
        typedef detail::try_lock_wrapper<recursive_mutex> scoped_try_lock;
#endif
    };

    typedef recursive_mutex recursive_try_mutex;

    class recursive_timed_mutex
    {
    private:
        pthread_mutex_t m;
#ifndef BOOST_USE_PTHREAD_RECURSIVE_TIMEDLOCK
        pthread_cond_t cond;
        bool is_locked;
        pthread_t owner;
        unsigned count;
#endif
    public:
        BOOST_THREAD_NO_COPYABLE(recursive_timed_mutex)
        recursive_timed_mutex()
        {
#ifdef BOOST_USE_PTHREAD_RECURSIVE_TIMEDLOCK
            pthread_mutexattr_t attr;

            int const init_attr_res=pthread_mutexattr_init(&attr);
            if(init_attr_res)
            {
                mwboost::throw_exception(thread_resource_error(init_attr_res, "mwboost:: recursive_timed_mutex constructor failed in pthread_mutexattr_init"));
            }
            int const set_attr_res=pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
            if(set_attr_res)
            {
                mwboost::throw_exception(thread_resource_error(set_attr_res, "mwboost:: recursive_timed_mutex constructor failed in pthread_mutexattr_settype"));
            }

            int const res=posix::pthread_mutex_init(&m,&attr);
            if(res)
            {
                BOOST_VERIFY(!pthread_mutexattr_destroy(&attr));
                mwboost::throw_exception(thread_resource_error(res, "mwboost:: recursive_timed_mutex constructor failed in pthread_mutex_init"));
            }
            BOOST_VERIFY(!pthread_mutexattr_destroy(&attr));
#else
            int const res=posix::pthread_mutex_init(&m);
            if(res)
            {
                mwboost::throw_exception(thread_resource_error(res, "mwboost:: recursive_timed_mutex constructor failed in pthread_mutex_init"));
            }
            int const res2=posix::pthread_cond_init(&cond);
            if(res2)
            {
                BOOST_VERIFY(!posix::pthread_mutex_destroy(&m));
                mwboost::throw_exception(thread_resource_error(res2, "mwboost:: recursive_timed_mutex constructor failed in pthread_cond_init"));
            }
            is_locked=false;
            count=0;
#endif
        }
        ~recursive_timed_mutex()
        {
            BOOST_VERIFY(!posix::pthread_mutex_destroy(&m));
#ifndef BOOST_USE_PTHREAD_RECURSIVE_TIMEDLOCK
            BOOST_VERIFY(!posix::pthread_cond_destroy(&cond));
#endif
        }

#if defined BOOST_THREAD_USES_DATETIME
        template<typename TimeDuration>
        bool timed_lock(TimeDuration const & relative_time)
        {
            if (relative_time.is_pos_infinity())
            {
                lock();
                return true;
            }
            if (relative_time.is_special())
            {
                return true;
            }
            detail::platform_duration d(relative_time);
#if defined(BOOST_THREAD_HAS_MONO_CLOCK) && !defined(BOOST_THREAD_INTERNAL_CLOCK_IS_MONO)
            const detail::mono_platform_timepoint ts(detail::mono_platform_clock::now() + d);
            d = (std::min)(d, detail::platform_milliseconds(BOOST_THREAD_POLL_INTERVAL_MILLISECONDS));
            while ( ! do_try_lock_until(detail::internal_platform_clock::now() + d) )
            {
              d = ts - detail::mono_platform_clock::now();
              if ( d <= detail::platform_duration::zero() ) return false; // timeout occurred
              d = (std::min)(d, detail::platform_milliseconds(BOOST_THREAD_POLL_INTERVAL_MILLISECONDS));
            }
            return true;
#else
            return do_try_lock_until(detail::internal_platform_clock::now() + d);
#endif
        }
#endif

#ifdef BOOST_USE_PTHREAD_RECURSIVE_TIMEDLOCK
        void lock()
        {
            BOOST_VERIFY(!posix::pthread_mutex_lock(&m));
        }

        void unlock()
        {
            BOOST_VERIFY(!posix::pthread_mutex_unlock(&m));
        }

        bool try_lock()
        {
            int const res=posix::pthread_mutex_trylock(&m);
            BOOST_ASSERT(!res || res==EBUSY);
            return !res;
        }
    private:
        bool do_try_lock_until(detail::internal_platform_timepoint const &timeout)
        {
            int const res=pthread_mutex_timedlock(&m,&timeout.getTs());
            BOOST_ASSERT(!res || res==ETIMEDOUT);
            return !res;
        }

    public:

#else
        void lock()
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(is_locked && pthread_equal(owner,pthread_self()))
            {
                ++count;
                return;
            }

            while(is_locked)
            {
                BOOST_VERIFY(!posix::pthread_cond_wait(&cond,&m));
            }
            is_locked=true;
            ++count;
            owner=pthread_self();
        }

        void unlock()
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(!--count)
            {
                is_locked=false;
            }
            BOOST_VERIFY(!posix::pthread_cond_signal(&cond));
        }

        bool try_lock() BOOST_NOEXCEPT
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(is_locked && !pthread_equal(owner,pthread_self()))
            {
                return false;
            }
            is_locked=true;
            ++count;
            owner=pthread_self();
            return true;
        }

    private:
        bool do_try_lock_until(detail::internal_platform_timepoint const &timeout)
        {
            mwboost::pthread::pthread_mutex_scoped_lock const local_lock(&m);
            if(is_locked && pthread_equal(owner,pthread_self()))
            {
                ++count;
                return true;
            }
            while(is_locked)
            {
                int const cond_res=posix::pthread_cond_timedwait(&cond,&m,&timeout.getTs());
                if(cond_res==ETIMEDOUT)
                {
                    break;
                }
                BOOST_ASSERT(!cond_res);
            }
            if(is_locked)
            {
                return false;
            }
            is_locked=true;
            ++count;
            owner=pthread_self();
            return true;
        }
    public:

#endif

#if defined BOOST_THREAD_USES_DATETIME
        bool timed_lock(system_time const & abs_time)
        {
            const detail::real_platform_timepoint ts(abs_time);
#if defined BOOST_THREAD_INTERNAL_CLOCK_IS_MONO
            detail::platform_duration d(ts - detail::real_platform_clock::now());
            d = (std::min)(d, detail::platform_milliseconds(BOOST_THREAD_POLL_INTERVAL_MILLISECONDS));
            while ( ! do_try_lock_until(detail::internal_platform_clock::now() + d) )
            {
              d = ts - detail::real_platform_clock::now();
              if ( d <= detail::platform_duration::zero() ) return false; // timeout occurred
              d = (std::min)(d, detail::platform_milliseconds(BOOST_THREAD_POLL_INTERVAL_MILLISECONDS));
            }
            return true;
#else
            return do_try_lock_until(ts);
#endif
        }
#endif
#ifdef BOOST_THREAD_USES_CHRONO
        template <class Rep, class Period>
        bool try_lock_for(const chrono::duration<Rep, Period>& rel_time)
        {
          return try_lock_until(chrono::steady_clock::now() + rel_time);
        }
        template <class Clock, class Duration>
        bool try_lock_until(const chrono::time_point<Clock, Duration>& t)
        {
          typedef typename common_type<Duration, typename Clock::duration>::type common_duration;
          common_duration d(t - Clock::now());
          d = (std::min)(d, common_duration(chrono::milliseconds(BOOST_THREAD_POLL_INTERVAL_MILLISECONDS)));
          while ( ! try_lock_until(detail::internal_chrono_clock::now() + d))
          {
              d = t - Clock::now();
              if ( d <= common_duration::zero() ) return false; // timeout occurred
              d = (std::min)(d, common_duration(chrono::milliseconds(BOOST_THREAD_POLL_INTERVAL_MILLISECONDS)));
          }
          return true;

        }
        template <class Duration>
        bool try_lock_until(const chrono::time_point<detail::internal_chrono_clock, Duration>& t)
        {
          detail::internal_platform_timepoint ts(t);
          return do_try_lock_until(ts);
        }
#endif

#define BOOST_THREAD_DEFINES_RECURSIVE_TIMED_MUTEX_NATIVE_HANDLE
        typedef pthread_mutex_t* native_handle_type;
        native_handle_type native_handle()
        {
            return &m;
        }

#if defined BOOST_THREAD_PROVIDES_NESTED_LOCKS
        typedef unique_lock<recursive_timed_mutex> scoped_timed_lock;
        typedef detail::try_lock_wrapper<recursive_timed_mutex> scoped_try_lock;
        typedef scoped_timed_lock scoped_lock;
#endif
    };

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
