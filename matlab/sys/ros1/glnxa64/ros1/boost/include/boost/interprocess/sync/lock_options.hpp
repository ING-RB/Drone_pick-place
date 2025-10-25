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

//////////////////////////////////////////////////////////////////////////////
//
// (C) Copyright Ion Gaztanaga 2005-2012. Distributed under the Boost
// Software License, Version 1.0. (See accompanying file
// LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org/libs/interprocess for documentation.
//
//////////////////////////////////////////////////////////////////////////////

#ifndef BOOST_INTERPROCESS_LOCK_OPTIONS_HPP
#define BOOST_INTERPROCESS_LOCK_OPTIONS_HPP

#ifndef BOOST_CONFIG_HPP
#  include <boost/config.hpp>
#endif
#
#if defined(BOOST_HAS_PRAGMA_ONCE)
#  pragma once
#endif

#include <boost/interprocess/detail/config_begin.hpp>
#include <boost/interprocess/detail/workaround.hpp>

//!\file
//!Describes the lock options with associated with interprocess_mutex lock constructors.

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace interprocess {

//!Type to indicate to a mutex lock constructor that must not lock the mutex.
struct defer_lock_type{};
//!Type to indicate to a mutex lock constructor that must try to lock the mutex.
struct try_to_lock_type {};
//!Type to indicate to a mutex lock constructor that the mutex is already locked.
struct accept_ownership_type{};

//!An object indicating that the locking
//!must be deferred.
static const defer_lock_type      defer_lock      = defer_lock_type();

//!An object indicating that a try_lock()
//!operation must be executed.
static const try_to_lock_type     try_to_lock    = try_to_lock_type();

//!An object indicating that the ownership of lockable
//!object must be accepted by the new owner.
static const accept_ownership_type  accept_ownership = accept_ownership_type();

} // namespace interprocess {
} // namespace mwboost {} namespace boost = mwboost; namespace mwboost{

#include <boost/interprocess/detail/config_end.hpp>

#endif // BOOST_INTERPROCESS_LOCK_OPTIONS_HPP

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
