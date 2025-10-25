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

// DEPRECATED in favor of adl_postconstruct and adl_predestruct with
// deconstruct<T>().
// A factory function for creating a shared_ptr that enhances the plain
// shared_ptr constructors by adding support for postconstructors
// and predestructors through the mwboost::signals2::postconstructible and
// mwboost::signals2::predestructible base classes.
//
// Copyright Frank Mori Hess 2007-2008.
//
// Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_SIGNALS2_DECONSTRUCT_PTR_HPP
#define BOOST_SIGNALS2_DECONSTRUCT_PTR_HPP

#include <boost/assert.hpp>
#include <boost/core/checked_delete.hpp>
#include <boost/core/no_exceptions_support.hpp>
#include <boost/signals2/postconstructible.hpp>
#include <boost/signals2/predestructible.hpp>
#include <boost/shared_ptr.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace signals2
  {
    namespace detail
    {
      inline void do_postconstruct(const postconstructible *ptr)
      {
        postconstructible *nonconst_ptr = const_cast<postconstructible*>(ptr);
        nonconst_ptr->postconstruct();
      }
      inline void do_postconstruct(...)
      {
      }
      inline void do_predestruct(...)
      {
      }
      inline void do_predestruct(const predestructible *ptr)
      {
        BOOST_TRY
        {
          predestructible *nonconst_ptr = const_cast<predestructible*>(ptr);
          nonconst_ptr->predestruct();
        }
        BOOST_CATCH(...)
        {
          BOOST_ASSERT(false);
        }
        BOOST_CATCH_END
      }
    }

    template<typename T> class predestructing_deleter
    {
    public:
      void operator()(const T *ptr) const
      {
        detail::do_predestruct(ptr);
        checked_delete(ptr);
      }
    };

    template<typename T>
    shared_ptr<T> deconstruct_ptr(T *ptr)
    {
      if(ptr == 0) return shared_ptr<T>(ptr);
      shared_ptr<T> shared(ptr, mwboost::signals2::predestructing_deleter<T>());
      detail::do_postconstruct(ptr);
      return shared;
    }
    template<typename T, typename D>
    shared_ptr<T> deconstruct_ptr(T *ptr, D deleter)
    {
      shared_ptr<T> shared(ptr, deleter);
      if(ptr == 0) return shared;
      detail::do_postconstruct(ptr);
      return shared;
    }
  }
}

#endif // BOOST_SIGNALS2_DECONSTRUCT_PTR_HPP

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
