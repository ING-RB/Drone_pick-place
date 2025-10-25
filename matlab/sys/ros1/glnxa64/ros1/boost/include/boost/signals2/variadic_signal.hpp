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

/*
  A variadic implementation of variadic mwboost::signals2::signal, used when variadic
  template support is detected in the compiler.

  Author: Frank Mori Hess <fmhess@users.sourceforge.net>
  Begin: 2009-05-26
*/
// Copyright Frank Mori Hess 2009
// Use, modification and
// distribution is subject to the Boost Software License, Version
// 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// For more information, see http://www.boost.org

#ifndef BOOST_SIGNALS2_VARIADIC_SIGNAL_HPP
#define BOOST_SIGNALS2_VARIADIC_SIGNAL_HPP

#include <boost/core/enable_if.hpp>
#include <boost/preprocessor/control/expr_if.hpp>
#include <boost/signals2/detail/variadic_arg_type.hpp>
#include <boost/signals2/detail/variadic_slot_invoker.hpp>
#include <boost/smart_ptr/make_shared.hpp>
#include <boost/type_traits/function_traits.hpp>
#include <boost/type_traits/is_void.hpp> 

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace signals2
  {
    namespace detail
    {
      template<typename Signature> class variadic_extended_signature;
      // partial template specialization
      template<typename R, typename ... Args>
        class variadic_extended_signature<R (Args...)>
      {
      public:
        typedef mwboost::function<R (const mwboost::signals2::connection &, Args...)> function_type;
      };
    } // namespace detail
  } // namespace signals2
} // namespace mwboost

#include <boost/signals2/detail/signal_template.hpp>

#endif // BOOST_SIGNALS2_VARIADIC_SIGNAL_HPP

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
