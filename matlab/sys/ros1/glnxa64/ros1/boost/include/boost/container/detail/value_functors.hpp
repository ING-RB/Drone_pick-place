#ifndef BOOST_CONTAINER_DETAIL_VALUE_FUNCTORS_HPP
#define BOOST_CONTAINER_DETAIL_VALUE_FUNCTORS_HPP
///////////////////////////////////////////////////////////////////////////////
//
// (C) Copyright Ion Gaztanaga 2017-2017. Distributed under the Boost
// Software License, Version 1.0. (See accompanying file
// LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// See http://www.boost.org/libs/container for documentation.
//
///////////////////////////////////////////////////////////////////////////////

#ifndef BOOST_CONFIG_HPP
#  include <boost/config.hpp>
#endif

#if defined(BOOST_HAS_PRAGMA_ONCE)
#  pragma once
#endif

#include <boost/intrusive/detail/value_functors.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {
namespace container {

using ::mwboost::intrusive::value_less;
using ::mwboost::intrusive::value_equal;

}  //namespace container {
}  //namespace mwboost {} namespace boost = mwboost; namespace mwboost {

#endif   //BOOST_CONTAINER_DETAIL_VALUE_FUNCTORS_HPP
