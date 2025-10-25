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

#ifndef BOOST_THREAD_LOCKABLE_TRAITS_HPP
#define BOOST_THREAD_LOCKABLE_TRAITS_HPP

#include <boost/thread/detail/config.hpp>

#include <boost/assert.hpp>
#include <boost/detail/workaround.hpp>
#include <boost/type_traits/integral_constant.hpp>
#ifdef BOOST_NO_CXX11_SFINAE_EXPR
#include <boost/type_traits/is_class.hpp>
#else
#include <boost/type_traits/declval.hpp>
#endif

#include <boost/config/abi_prefix.hpp>

// todo make use of integral_constant, true_type and false_type

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
  namespace sync
  {

#if defined(BOOST_NO_SFINAE) ||                           \
    BOOST_WORKAROUND(__IBMCPP__, BOOST_TESTED_AT(600)) || \
    BOOST_WORKAROUND(__SUNPRO_CC, BOOST_TESTED_AT(0x590))
#if ! defined BOOST_THREAD_NO_AUTO_DETECT_MUTEX_TYPES
#define BOOST_THREAD_NO_AUTO_DETECT_MUTEX_TYPES
#endif
#endif

#ifndef BOOST_THREAD_NO_AUTO_DETECT_MUTEX_TYPES
    namespace detail
    {
#ifdef BOOST_NO_CXX11_SFINAE_EXPR
#define BOOST_THREAD_DEFINE_HAS_MEMBER_CALLED(member_name)                     \
        template<typename T, bool=mwboost::is_class<T>::value>            \
        struct has_member_called_##member_name                          \
        {                                                               \
            BOOST_STATIC_CONSTANT(bool, value=false);                   \
        };                                                              \
                                                                        \
        template<typename T>                                            \
        struct has_member_called_##member_name<T,true>                  \
        {                                                               \
            typedef char true_type;                                     \
            struct false_type                                           \
            {                                                           \
                true_type dummy[2];                                     \
            };                                                          \
                                                                        \
            struct fallback { int member_name; };                       \
            struct derived:                                             \
                T, fallback                                             \
            {                                                           \
                derived();                                              \
            };                                                          \
                                                                        \
            template<int fallback::*> struct tester;                    \
                                                                        \
            template<typename U>                                        \
                static false_type has_member(tester<&U::member_name>*); \
            template<typename U>                                        \
                static true_type has_member(...);                       \
                                                                        \
            BOOST_STATIC_CONSTANT(                                      \
                bool, value=sizeof(has_member<derived>(0))==sizeof(true_type)); \
        }

      BOOST_THREAD_DEFINE_HAS_MEMBER_CALLED(lock)
;      BOOST_THREAD_DEFINE_HAS_MEMBER_CALLED(unlock);
      BOOST_THREAD_DEFINE_HAS_MEMBER_CALLED(try_lock);

      template<typename T,bool=has_member_called_lock<T>::value >
      struct has_member_lock
      {
        BOOST_STATIC_CONSTANT(bool, value=false);
      };

      template<typename T>
      struct has_member_lock<T,true>
      {
        typedef char true_type;
        struct false_type
        {
          true_type dummy[2];
        };

        template<typename U,typename V>
        static true_type has_member(V (U::*)());
        template<typename U>
        static false_type has_member(U);

        BOOST_STATIC_CONSTANT(
            bool,value=sizeof(has_member_lock<T>::has_member(&T::lock))==sizeof(true_type));
      };

      template<typename T,bool=has_member_called_unlock<T>::value >
      struct has_member_unlock
      {
        BOOST_STATIC_CONSTANT(bool, value=false);
      };

      template<typename T>
      struct has_member_unlock<T,true>
      {
        typedef char true_type;
        struct false_type
        {
          true_type dummy[2];
        };

        template<typename U,typename V>
        static true_type has_member(V (U::*)());
        template<typename U>
        static false_type has_member(U);

        BOOST_STATIC_CONSTANT(
            bool,value=sizeof(has_member_unlock<T>::has_member(&T::unlock))==sizeof(true_type));
      };

      template<typename T,bool=has_member_called_try_lock<T>::value >
      struct has_member_try_lock
      {
        BOOST_STATIC_CONSTANT(bool, value=false);
      };

      template<typename T>
      struct has_member_try_lock<T,true>
      {
        typedef char true_type;
        struct false_type
        {
          true_type dummy[2];
        };

        template<typename U>
        static true_type has_member(bool (U::*)());
        template<typename U>
        static false_type has_member(U);

        BOOST_STATIC_CONSTANT(
            bool,value=sizeof(has_member_try_lock<T>::has_member(&T::try_lock))==sizeof(true_type));
      };
#else
      template<typename T,typename Enabled=void>
      struct has_member_lock : false_type {};

      template<typename T>
      struct has_member_lock<T,
          decltype(void(mwboost::declval<T&>().lock()))
      > : true_type {};

      template<typename T,typename Enabled=void>
      struct has_member_unlock : false_type {};

      template<typename T>
      struct has_member_unlock<T,
          decltype(void(mwboost::declval<T&>().unlock()))
      > : true_type {};

      template<typename T,typename Enabled=bool>
      struct has_member_try_lock : false_type {};

      template<typename T>
      struct has_member_try_lock<T,
          decltype(bool(mwboost::declval<T&>().try_lock()))
      > : true_type {};
#endif

    }

    template<typename T>
    struct is_basic_lockable
    {
      BOOST_STATIC_CONSTANT(bool, value = detail::has_member_lock<T>::value &&
          detail::has_member_unlock<T>::value);
    };
    template<typename T>
    struct is_lockable
    {
      BOOST_STATIC_CONSTANT(bool, value =
          is_basic_lockable<T>::value &&
          detail::has_member_try_lock<T>::value);
    };

#else
    template<typename T>
    struct is_basic_lockable
    {
      BOOST_STATIC_CONSTANT(bool, value = false);
    };
    template<typename T>
    struct is_lockable
    {
      BOOST_STATIC_CONSTANT(bool, value = false);
    };
#endif

    template<typename T>
    struct is_recursive_mutex_sur_parole
    {
      BOOST_STATIC_CONSTANT(bool, value = false);
    };
    template<typename T>
    struct is_recursive_mutex_sur_parolle : is_recursive_mutex_sur_parole<T>
    {
    };

    template<typename T>
    struct is_recursive_basic_lockable
    {
      BOOST_STATIC_CONSTANT(bool, value = is_basic_lockable<T>::value &&
          is_recursive_mutex_sur_parolle<T>::value);
    };
    template<typename T>
    struct is_recursive_lockable
    {
      BOOST_STATIC_CONSTANT(bool, value = is_lockable<T>::value &&
          is_recursive_mutex_sur_parolle<T>::value);
    };
  }
  template<typename T>
  struct is_mutex_type
  {
    BOOST_STATIC_CONSTANT(bool, value = sync::is_lockable<T>::value);
  };

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
