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
// (C) Copyright 2007 Anthony Williams
// (C) Copyright 2011-2012 Vicente J. Botet Escriba

#ifndef BOOST_THREAD_LOCK_GUARD_HPP
#define BOOST_THREAD_LOCK_GUARD_HPP

#include <boost/thread/detail/config.hpp>
#include <boost/thread/detail/delete.hpp>
#include <boost/thread/detail/move.hpp>
#include <boost/thread/detail/lockable_wrapper.hpp>
#include <boost/thread/lock_options.hpp>
#if ! defined BOOST_THREAD_PROVIDES_NESTED_LOCKS
#include <boost/thread/is_locked_by_this_thread.hpp>
#include <boost/assert.hpp>
#endif

#include <boost/config/abi_prefix.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

  template <typename Mutex>
  class BOOST_THREAD_SCOPED_CAPABILITY lock_guard
  {
  private:
    Mutex& m;

  public:
    typedef Mutex mutex_type;
    BOOST_THREAD_NO_COPYABLE( lock_guard )

    explicit lock_guard(Mutex& m_) BOOST_THREAD_ACQUIRE(m_) :
      m(m_)
    {
      m.lock();
    }

    lock_guard(Mutex& m_, adopt_lock_t) BOOST_THREAD_REQUIRES(m_) :
      m(m_)
    {
#if ! defined BOOST_THREAD_PROVIDES_NESTED_LOCKS
      BOOST_ASSERT(is_locked_by_this_thread(m));
#endif
    }

#if ! defined BOOST_THREAD_NO_CXX11_HDR_INITIALIZER_LIST
    lock_guard(std::initializer_list<thread_detail::lockable_wrapper<Mutex> > l_) :
      m(*(const_cast<thread_detail::lockable_wrapper<Mutex>*>(l_.begin())->m))
    {
      m.lock();
    }

    lock_guard(std::initializer_list<thread_detail::lockable_adopt_wrapper<Mutex> > l_) :
      m(*(const_cast<thread_detail::lockable_adopt_wrapper<Mutex>*>(l_.begin())->m))
    {
#if ! defined BOOST_THREAD_PROVIDES_NESTED_LOCKS
      BOOST_ASSERT(is_locked_by_this_thread(m));
#endif
    }

#endif
    ~lock_guard() BOOST_THREAD_RELEASE()
    {
      m.unlock();
    }
  };


#if ! defined BOOST_THREAD_NO_MAKE_LOCK_GUARD
  template <typename Lockable>
  lock_guard<Lockable> make_lock_guard(Lockable& mtx)
  {
    return { thread_detail::lockable_wrapper<Lockable>(mtx) };
  }
  template <typename Lockable>
  lock_guard<Lockable> make_lock_guard(Lockable& mtx, adopt_lock_t)
  {
    return { thread_detail::lockable_adopt_wrapper<Lockable>(mtx) };
  }
#endif
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
