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

// Boost.Signals2 library

// Copyright Frank Mori Hess 2007-2008.
// Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org

#ifndef BOOST_SIGNALS2_SHARED_CONNECTION_BLOCK_HPP
#define BOOST_SIGNALS2_SHARED_CONNECTION_BLOCK_HPP

#include <boost/shared_ptr.hpp>
#include <boost/signals2/connection.hpp>
#include <boost/weak_ptr.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace signals2
  {
    class shared_connection_block
    {
    public:
      shared_connection_block(const signals2::connection &conn = signals2::connection(),
        bool initially_blocked = true):
        _weak_connection_body(conn._weak_connection_body)
      {
        if(initially_blocked) block();
      }
      void block()
      {
        if(blocking()) return;
        mwboost::shared_ptr<detail::connection_body_base> connection_body(_weak_connection_body.lock());
        if(connection_body == 0)
        {
          // Make _blocker non-empty so the blocking() method still returns the correct value
          // after the connection has expired.
          _blocker.reset(static_cast<int*>(0));
          return;
        }
        _blocker = connection_body->get_blocker();
      }
      void unblock()
      {
        _blocker.reset();
      }
      bool blocking() const
      {
        shared_ptr<void> empty;
        return _blocker < empty || empty < _blocker;
      }
      signals2::connection connection() const
      {
        return signals2::connection(_weak_connection_body);
      }
    private:
      mwboost::weak_ptr<detail::connection_body_base> _weak_connection_body;
      shared_ptr<void> _blocker;
    };
  }
} // end namespace mwboost

#endif // BOOST_SIGNALS2_SHARED_CONNECTION_BLOCK_HPP

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
