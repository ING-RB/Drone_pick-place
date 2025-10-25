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

//  (C) Copyright 2008-10 Anthony Williams
//  (C) Copyright 2011-2012,2015 Vicente J. Botet Escriba
//
//  Distributed under the Boost Software License, Version 1.0. (See
//  accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_THREAD_FUTURES_FUTURE_ERROR_CODE_HPP
#define BOOST_THREAD_FUTURES_FUTURE_ERROR_CODE_HPP

#include <boost/thread/detail/config.hpp>
#include <boost/core/scoped_enum.hpp>
#include <boost/system/error_code.hpp>
#include <boost/type_traits/integral_constant.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{

  //enum class future_errc
  BOOST_SCOPED_ENUM_DECLARE_BEGIN(future_errc)
  {
      broken_promise = 1,
      future_already_retrieved,
      promise_already_satisfied,
      no_state
  }
  BOOST_SCOPED_ENUM_DECLARE_END(future_errc)

  namespace system
  {
    template <>
    struct BOOST_SYMBOL_VISIBLE is_error_code_enum< ::mwboost::future_errc> : public true_type {};

    #ifdef BOOST_NO_CXX11_SCOPED_ENUMS
    template <>
    struct BOOST_SYMBOL_VISIBLE is_error_code_enum< ::mwboost::future_errc::enum_type> : public true_type { };
    #endif
  } // system

  BOOST_THREAD_DECL
  const system::error_category& future_category() BOOST_NOEXCEPT;

  namespace system
  {
    inline
    error_code
    make_error_code(future_errc e) BOOST_NOEXCEPT
    {
        return error_code(underlying_cast<int>(e), mwboost::future_category());
    }

    inline
    error_condition
    make_error_condition(future_errc e) BOOST_NOEXCEPT
    {
        return error_condition(underlying_cast<int>(e), mwboost::future_category());
    }
  } // system
} // boost

#endif // header

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
