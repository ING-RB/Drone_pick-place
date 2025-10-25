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


// Copyright (C) 2008-2011 Daniel James.
// Copyright (C) 2022 Christian Mazakas
// Distributed under the Boost Software License, Version 1.0. (See accompanying
// file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_UNORDERED_MAP_FWD_HPP_INCLUDED
#define BOOST_UNORDERED_MAP_FWD_HPP_INCLUDED

#include <boost/config.hpp>
#if defined(BOOST_HAS_PRAGMA_ONCE)
#pragma once
#endif

#include <boost/functional/hash_fwd.hpp>
#include <boost/unordered/detail/fwd.hpp>
#include <functional>
#include <memory>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
  namespace unordered {
    template <class K, class T, class H = mwboost::hash<K>,
      class P = std::equal_to<K>,
      class A = std::allocator<std::pair<const K, T> > >
    class unordered_map;

    template <class K, class T, class H, class P, class A>
    inline bool operator==(
      unordered_map<K, T, H, P, A> const&, unordered_map<K, T, H, P, A> const&);
    template <class K, class T, class H, class P, class A>
    inline bool operator!=(
      unordered_map<K, T, H, P, A> const&, unordered_map<K, T, H, P, A> const&);
    template <class K, class T, class H, class P, class A>
    inline void swap(
      unordered_map<K, T, H, P, A>& m1, unordered_map<K, T, H, P, A>& m2)
      BOOST_NOEXCEPT_IF(BOOST_NOEXCEPT_EXPR(m1.swap(m2)));

    template <class K, class T, class H, class P, class A, class Predicate>
    typename unordered_map<K, T, H, P, A>::size_type erase_if(
      unordered_map<K, T, H, P, A>& c, Predicate pred);

    template <class K, class T, class H = mwboost::hash<K>,
      class P = std::equal_to<K>,
      class A = std::allocator<std::pair<const K, T> > >
    class unordered_multimap;

    template <class K, class T, class H, class P, class A>
    inline bool operator==(unordered_multimap<K, T, H, P, A> const&,
      unordered_multimap<K, T, H, P, A> const&);
    template <class K, class T, class H, class P, class A>
    inline bool operator!=(unordered_multimap<K, T, H, P, A> const&,
      unordered_multimap<K, T, H, P, A> const&);
    template <class K, class T, class H, class P, class A>
    inline void swap(unordered_multimap<K, T, H, P, A>& m1,
      unordered_multimap<K, T, H, P, A>& m2)
      BOOST_NOEXCEPT_IF(BOOST_NOEXCEPT_EXPR(m1.swap(m2)));

    template <class K, class T, class H, class P, class A, class Predicate>
    typename unordered_multimap<K, T, H, P, A>::size_type erase_if(
      unordered_multimap<K, T, H, P, A>& c, Predicate pred);

    template <class N, class K, class T, class A> class node_handle_map;
    template <class Iter, class NodeType> struct insert_return_type_map;
  }

  using mwboost::unordered::unordered_map;
  using mwboost::unordered::unordered_multimap;
  using mwboost::unordered::swap;
  using mwboost::unordered::operator==;
  using mwboost::unordered::operator!=;
}

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
