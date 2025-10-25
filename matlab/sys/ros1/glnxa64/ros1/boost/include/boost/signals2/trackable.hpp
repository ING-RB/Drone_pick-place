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

// Copyright Frank Mori Hess 2007,2009.
// Copyright Timmo Stange 2007.
// Copyright Douglas Gregor 2001-2004. Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// Compatibility class to ease porting from the original
// Boost.Signals library.  However,
// mwboost::signals2::trackable is NOT thread-safe.

// For more information, see http://www.boost.org

#ifndef BOOST_SIGNALS2_TRACKABLE_HPP
#define BOOST_SIGNALS2_TRACKABLE_HPP

#include <boost/assert.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
  namespace signals2 {
    namespace detail
    {
        class tracked_objects_visitor;
        
        // trackable_pointee is used to identify the tracked shared_ptr 
        // originating from the signals2::trackable class.  These tracked
        // shared_ptr are special in that we shouldn't bother to
        // increment their use count during signal invocation, since
        // they don't actually control the lifetime of the
        // signals2::trackable object they are associated with.
        class trackable_pointee
        {};
    }
    class trackable {
    protected:
      trackable(): _tracked_ptr(static_cast<detail::trackable_pointee*>(0)) {}
      trackable(const trackable &): _tracked_ptr(static_cast<detail::trackable_pointee*>(0)) {}
      trackable& operator=(const trackable &)
      {
          return *this;
      }
      ~trackable() {}
    private:
      friend class detail::tracked_objects_visitor;
      weak_ptr<detail::trackable_pointee> get_weak_ptr() const
      {
          return _tracked_ptr;
      }

      shared_ptr<detail::trackable_pointee> _tracked_ptr;
    };
  } // end namespace signals2
} // end namespace mwboost

#endif // BOOST_SIGNALS2_TRACKABLE_HPP

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
