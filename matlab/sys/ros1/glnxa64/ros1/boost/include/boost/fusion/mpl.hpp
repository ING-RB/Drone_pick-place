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

/*=============================================================================
    Copyright (c) 2001-2011 Joel de Guzman

    Distributed under the Boost Software License, Version 1.0. (See accompanying
    file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
==============================================================================*/
#if !defined(FUSION_MPL_09172006_2049)
#define FUSION_MPL_09172006_2049

// The fusion <--> MPL link headers
#include <boost/fusion/iterator/mpl.hpp>
#include <boost/fusion/adapted/mpl.hpp>

#include <boost/fusion/mpl/at.hpp>
#include <boost/fusion/mpl/back.hpp>
#include <boost/fusion/mpl/begin.hpp>
#include <boost/fusion/mpl/clear.hpp>
#include <boost/fusion/mpl/empty.hpp>
#include <boost/fusion/mpl/end.hpp>
#include <boost/fusion/mpl/erase.hpp>
#include <boost/fusion/mpl/erase_key.hpp>
#include <boost/fusion/mpl/front.hpp>
#include <boost/fusion/mpl/has_key.hpp>
#include <boost/fusion/mpl/insert.hpp>
#include <boost/fusion/mpl/insert_range.hpp>
#include <boost/fusion/mpl/pop_back.hpp>
#include <boost/fusion/mpl/pop_front.hpp>
#include <boost/fusion/mpl/push_back.hpp>
#include <boost/fusion/mpl/push_front.hpp>
#include <boost/fusion/mpl/size.hpp>

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
