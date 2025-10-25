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

// optional_last_value function object (documented as part of Boost.Signals2)

// Copyright Frank Mori Hess 2007-2008.
// Copyright Douglas Gregor 2001-2003.
// Distributed under the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// See http://www.boost.org/libs/signals2 for library home page.

#ifndef BOOST_SIGNALS2_OPTIONAL_LAST_VALUE_HPP
#define BOOST_SIGNALS2_OPTIONAL_LAST_VALUE_HPP

#include <boost/core/no_exceptions_support.hpp>
#include <boost/optional.hpp>
#include <boost/signals2/expired_slot.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
  namespace signals2 {

    template<typename T>
      class optional_last_value
    {
    public:
      typedef optional<T> result_type;

      template<typename InputIterator>
        optional<T> operator()(InputIterator first, InputIterator last) const
      {
        optional<T> value;
        while (first != last)
        {
          BOOST_TRY
          {
            value = *first;
          }
          BOOST_CATCH(const expired_slot &) {}
          BOOST_CATCH_END
          ++first;
        }
        return value;
      }
    };

    template<>
      class optional_last_value<void>
    {
    public:
      typedef void result_type;
      template<typename InputIterator>
        result_type operator()(InputIterator first, InputIterator last) const
      {
        while (first != last)
        {
          BOOST_TRY
          {
            *first;
          }
          BOOST_CATCH(const expired_slot &) {}
          BOOST_CATCH_END
          ++first;
        }
        return;
      }
    };
  } // namespace signals2
} // namespace mwboost
#endif // BOOST_SIGNALS2_OPTIONAL_LAST_VALUE_HPP

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
