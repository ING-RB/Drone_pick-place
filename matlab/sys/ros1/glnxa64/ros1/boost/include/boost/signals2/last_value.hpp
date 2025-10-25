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

// last_value function object (documented as part of Boost.Signals)

// Copyright Frank Mori Hess 2007.
// Copyright Douglas Gregor 2001-2003. Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org

#ifndef BOOST_SIGNALS2_LAST_VALUE_HPP
#define BOOST_SIGNALS2_LAST_VALUE_HPP

#include <boost/core/no_exceptions_support.hpp>
#include <boost/optional.hpp>
#include <boost/signals2/expired_slot.hpp>
#include <boost/throw_exception.hpp>
#include <stdexcept>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
  namespace signals2 {

    // no_slots_error is thrown when we are unable to generate a return value
    // due to no slots being connected to the signal.
    class no_slots_error: public std::exception
    {
    public:
      virtual const char* what() const throw() {return "mwboost::signals2::no_slots_error";}
    };

    template<typename T>
    class last_value {
    public:
      typedef T result_type;

      template<typename InputIterator>
      T operator()(InputIterator first, InputIterator last) const
      {
        if(first == last)
        {
          mwboost::throw_exception(no_slots_error());
        }
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
        if(value) return value.get();
        mwboost::throw_exception(no_slots_error());
      }
    };

    template<>
    class last_value<void> {
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
#endif // BOOST_SIGNALS2_LAST_VALUE_HPP

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
