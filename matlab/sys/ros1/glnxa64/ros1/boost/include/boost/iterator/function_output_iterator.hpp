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

// (C) Copyright Jeremy Siek 2001.
// Distributed under the Boost Software License, Version 1.0. (See
// accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)

// Revision History:

// 27 Feb 2001   Jeremy Siek
//      Initial checkin.

#ifndef BOOST_ITERATOR_FUNCTION_OUTPUT_ITERATOR_HPP
#define BOOST_ITERATOR_FUNCTION_OUTPUT_ITERATOR_HPP

#include <iterator>
#include <boost/config.hpp>
#include <boost/core/enable_if.hpp>
#include <boost/type_traits/is_same.hpp>
#include <boost/type_traits/remove_cv.hpp>
#ifndef BOOST_NO_CXX11_RVALUE_REFERENCES
#include <boost/type_traits/remove_reference.hpp>
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace iterators {

  template <class UnaryFunction>
  class function_output_iterator {
  private:
    typedef function_output_iterator self;

    class output_proxy {
    public:
      explicit output_proxy(UnaryFunction& f) BOOST_NOEXCEPT : m_f(f) { }

#ifdef BOOST_NO_CXX11_RVALUE_REFERENCES
      template <class T>
      typename mwboost::disable_if_c<
        mwboost::is_same< typename mwboost::remove_cv< T >::type, output_proxy >::value,
        output_proxy&
      >::type operator=(const T& value) {
        m_f(value);
        return *this;
      }
#else
      template <class T>
      typename mwboost::disable_if_c<
        mwboost::is_same< typename mwboost::remove_cv< typename mwboost::remove_reference< T >::type >::type, output_proxy >::value,
        output_proxy&
      >::type operator=(T&& value) {
        m_f(static_cast< T&& >(value));
        return *this;
      }
#endif

      BOOST_DEFAULTED_FUNCTION(output_proxy(output_proxy const& that), BOOST_NOEXCEPT : m_f(that.m_f) {})
      BOOST_DELETED_FUNCTION(output_proxy& operator=(output_proxy const&))

    private:
      UnaryFunction& m_f;
    };

  public:
    typedef std::output_iterator_tag iterator_category;
    typedef void                value_type;
    typedef void                difference_type;
    typedef void                pointer;
    typedef void                reference;

    explicit function_output_iterator() {}

    explicit function_output_iterator(const UnaryFunction& f)
      : m_f(f) {}

    output_proxy operator*() { return output_proxy(m_f); }
    self& operator++() { return *this; }
    self& operator++(int) { return *this; }

  private:
    UnaryFunction m_f;
  };

  template <class UnaryFunction>
  inline function_output_iterator<UnaryFunction>
  make_function_output_iterator(const UnaryFunction& f = UnaryFunction()) {
    return function_output_iterator<UnaryFunction>(f);
  }

} // namespace iterators

using iterators::function_output_iterator;
using iterators::make_function_output_iterator;

} // namespace mwboost

#endif // BOOST_ITERATOR_FUNCTION_OUTPUT_ITERATOR_HPP

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
