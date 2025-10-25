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

//  (C) Copyright Antony Polukhin 2013.
//
//  Use, modification and distribution are subject to the Boost Software License,
//  Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt).
//
//  See http://www.boost.org/libs/type_traits for most recent version including documentation.

#ifndef BOOST_TT_IS_COPY_CONSTRUCTIBLE_HPP_INCLUDED
#define BOOST_TT_IS_COPY_CONSTRUCTIBLE_HPP_INCLUDED

#include <boost/config.hpp>
#include <boost/detail/workaround.hpp>

#if !defined(BOOST_NO_CXX11_VARIADIC_TEMPLATES) && !defined(BOOST_NO_CXX11_DECLTYPE) && !BOOST_WORKAROUND(BOOST_MSVC, < 1800) && !BOOST_WORKAROUND(BOOST_GCC_VERSION, < 40900)

#include <boost/type_traits/is_constructible.hpp>

#if !BOOST_WORKAROUND(BOOST_MSVC, <= 1800)

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

template <class T> struct is_copy_constructible : public mwboost::is_constructible<T, const T&>{};

template <> struct is_copy_constructible<void> : public false_type{};
template <> struct is_copy_constructible<void const> : public false_type{};
template <> struct is_copy_constructible<void const volatile> : public false_type{};
template <> struct is_copy_constructible<void volatile> : public false_type{};

} // namespace mwboost

#else
//
// Special version for VC12 which has a problem when a base class (such as non_copyable) has a deleted
// copy constructor.  In this case the compiler thinks there really is a copy-constructor and tries to
// instantiate the deleted member.  std::is_copy_constructible has the same issue (or at least returns
// an incorrect value, which just defers the issue into the users code) as well.  We can at least fix
// mwboost::non_copyable as a base class as a special case:
//
#include <boost/type_traits/is_noncopyable.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

   namespace detail
   {

      template <class T, bool b> struct is_copy_constructible_imp : public mwboost::is_constructible<T, const T&>{};
      template <class T> struct is_copy_constructible_imp<T, true> : public false_type{};

   }

   template <class T> struct is_copy_constructible : public detail::is_copy_constructible_imp<T, is_noncopyable<T>::value>{};

   template <> struct is_copy_constructible<void> : public false_type{};
   template <> struct is_copy_constructible<void const> : public false_type{};
   template <> struct is_copy_constructible<void const volatile> : public false_type{};
   template <> struct is_copy_constructible<void volatile> : public false_type{};

} // namespace mwboost

#endif

#else

#include <boost/type_traits/detail/yes_no_type.hpp>
#include <boost/type_traits/is_noncopyable.hpp>
#include <boost/type_traits/add_reference.hpp>
#include <boost/type_traits/is_rvalue_reference.hpp>
#include <boost/type_traits/declval.hpp>
#include <boost/type_traits/is_array.hpp>
#include <boost/type_traits/declval.hpp>

#ifdef BOOST_MSVC
#pragma warning(push)
#pragma warning(disable:4181)
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

   namespace detail{

      template <bool DerivedFromNoncopyable, class T>
      struct is_copy_constructible_impl2 {

         // Intel compiler has problems with SFINAE for copy constructors and deleted functions:
         //
         // error: function *function_name* cannot be referenced -- it is a deleted function
         // static mwboost::type_traits::yes_type test(T1&, decltype(T1(mwboost::declval<T1&>()))* = 0);
         //                                                        ^ 
         //
         // MSVC 12.0 (Visual 2013) has problems when the copy constructor has been deleted. See:
         // https://connect.microsoft.com/VisualStudio/feedback/details/800328/std-is-copy-constructible-is-broken
#if !defined(BOOST_NO_CXX11_DELETED_FUNCTIONS) && !defined(BOOST_INTEL_CXX_VERSION) && !(defined(BOOST_MSVC) && _MSC_VER == 1800)

#ifdef BOOST_NO_CXX11_DECLTYPE
         template <class T1>
         static mwboost::type_traits::yes_type test(const T1&, mwboost::mpl::int_<sizeof(T1(mwboost::declval<const T1&>()))>* = 0);
#else
         template <class T1>
         static mwboost::type_traits::yes_type test(const T1&, decltype(T1(mwboost::declval<const T1&>()))* = 0);
#endif

         static mwboost::type_traits::no_type test(...);
#else
         template <class T1>
         static mwboost::type_traits::no_type test(const T1&, typename T1::boost_move_no_copy_constructor_or_assign* = 0);
         static mwboost::type_traits::yes_type test(...);
#endif

         // If you see errors like this:
         //
         //      `'T::T(const T&)' is private`
         //      `boost/type_traits/is_copy_constructible.hpp:68:5: error: within this context`
         //
         // then you are trying to call that macro for a structure defined like that:
         //
         //      struct T {
         //          ...
         //      private:
         //          T(const T &);
         //          ...
         //      };
         //
         // To fix that you must modify your structure:
         //
         //      // C++03 and C++11 version
         //      struct T: private mwboost::noncopyable {
         //          ...
         //      private:
         //          T(const T &);
         //          ...
         //      };
         //
         //      // C++11 version
         //      struct T {
         //          ...
         //      private:
         //          T(const T &) = delete;
         //          ...
         //      };
         BOOST_STATIC_CONSTANT(bool, value = (
            sizeof(test(
            mwboost::declval<BOOST_DEDUCED_TYPENAME mwboost::add_reference<T const>::type>()
            )) == sizeof(mwboost::type_traits::yes_type)
            &&
            !mwboost::is_rvalue_reference<T>::value
            && !mwboost::is_array<T>::value
            ));
      };

      template <class T>
      struct is_copy_constructible_impl2<true, T> {
         BOOST_STATIC_CONSTANT(bool, value = false);
      };

      template <class T>
      struct is_copy_constructible_impl {

         BOOST_STATIC_CONSTANT(bool, value = (
            mwboost::detail::is_copy_constructible_impl2<
            mwboost::is_noncopyable<T>::value,
            T
            >::value
            ));
      };

   } // namespace detail

   template <class T> struct is_copy_constructible : public integral_constant<bool, ::mwboost::detail::is_copy_constructible_impl<T>::value>{};
   template <> struct is_copy_constructible<void> : public false_type{};
#ifndef BOOST_NO_CV_VOID_SPECIALIZATIONS
   template <> struct is_copy_constructible<void const> : public false_type{};
   template <> struct is_copy_constructible<void volatile> : public false_type{};
   template <> struct is_copy_constructible<void const volatile> : public false_type{};
#endif

} // namespace mwboost

#ifdef BOOST_MSVC
#pragma warning(pop)
#endif

#endif

#endif // BOOST_TT_IS_COPY_CONSTRUCTIBLE_HPP_INCLUDED

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
