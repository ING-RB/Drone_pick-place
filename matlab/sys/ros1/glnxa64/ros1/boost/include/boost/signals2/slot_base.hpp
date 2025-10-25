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
// Copyright Timmo Stange 2007.
// Copyright Douglas Gregor 2001-2004. Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org

#ifndef BOOST_SIGNALS2_SLOT_BASE_HPP
#define BOOST_SIGNALS2_SLOT_BASE_HPP

#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>
#include <boost/signals2/detail/foreign_ptr.hpp>
#include <boost/signals2/expired_slot.hpp>
#include <boost/signals2/signal_base.hpp>
#include <boost/throw_exception.hpp>
#include <boost/variant/apply_visitor.hpp>
#include <boost/variant/variant.hpp>
#include <vector>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace signals2
  {
    namespace detail
    {
      class tracked_objects_visitor;
      class trackable_pointee;

      typedef mwboost::variant<mwboost::weak_ptr<trackable_pointee>, mwboost::weak_ptr<void>, detail::foreign_void_weak_ptr > void_weak_ptr_variant;
      typedef mwboost::variant<mwboost::shared_ptr<void>, detail::foreign_void_shared_ptr > void_shared_ptr_variant;
      class lock_weak_ptr_visitor
      {
      public:
        typedef void_shared_ptr_variant result_type;
        template<typename WeakPtr>
        result_type operator()(const WeakPtr &wp) const
        {
          return wp.lock();
        }
        // overload to prevent incrementing use count of shared_ptr associated
        // with signals2::trackable objects
        result_type operator()(const weak_ptr<trackable_pointee> &) const
        {
          return mwboost::shared_ptr<void>();
        }
      };
      class expired_weak_ptr_visitor
      {
      public:
        typedef bool result_type;
        template<typename WeakPtr>
        bool operator()(const WeakPtr &wp) const
        {
          return wp.expired();
        }
      };
    }

    class slot_base
    {
    public:
      typedef std::vector<detail::void_weak_ptr_variant> tracked_container_type;
      typedef std::vector<detail::void_shared_ptr_variant> locked_container_type;

      const tracked_container_type& tracked_objects() const {return _tracked_objects;}
      locked_container_type lock() const
      {
        locked_container_type locked_objects;
        tracked_container_type::const_iterator it;
        for(it = tracked_objects().begin(); it != tracked_objects().end(); ++it)
        {
          locked_objects.push_back(apply_visitor(detail::lock_weak_ptr_visitor(), *it));
          if(apply_visitor(detail::expired_weak_ptr_visitor(), *it))
          {
            mwboost::throw_exception(expired_slot());
          }
        }
        return locked_objects;
      }
      bool expired() const
      {
        tracked_container_type::const_iterator it;
        for(it = tracked_objects().begin(); it != tracked_objects().end(); ++it)
        {
          if(apply_visitor(detail::expired_weak_ptr_visitor(), *it)) return true;
        }
        return false;
      }
    protected:
      friend class detail::tracked_objects_visitor;

      void track_signal(const signal_base &signal)
      {
        _tracked_objects.push_back(signal.lock_pimpl());
      }

      tracked_container_type _tracked_objects;
    };
  }
} // end namespace mwboost

#endif // BOOST_SIGNALS2_SLOT_BASE_HPP

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
