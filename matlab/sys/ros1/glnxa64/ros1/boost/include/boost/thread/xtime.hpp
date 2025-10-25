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

// Copyright (C) 2001-2003
// William E. Kempf
// Copyright (C) 2007-8 Anthony Williams
//
//  Distributed under the Boost Software License, Version 1.0. (See accompanying
//  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)

#ifndef BOOST_XTIME_WEK070601_HPP
#define BOOST_XTIME_WEK070601_HPP

#include <boost/thread/detail/config.hpp>
#if defined BOOST_THREAD_USES_DATETIME

#include <boost/cstdint.hpp>
#include <boost/thread/thread_time.hpp>
#include <boost/date_time/posix_time/conversion.hpp>

#include <boost/config/abi_prefix.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost {

enum xtime_clock_types
{
    TIME_UTC_=1
//    TIME_TAI,
//    TIME_MONOTONIC,
//    TIME_PROCESS,
//    TIME_THREAD,
//    TIME_LOCAL,
//    TIME_SYNC,
//    TIME_RESOLUTION
};

struct xtime
{
#if defined(BOOST_NO_INT64_T)
    typedef int_fast32_t xtime_sec_t; //INT_FAST32_MIN <= sec <= INT_FAST32_MAX
#else
    typedef int_fast64_t xtime_sec_t; //INT_FAST64_MIN <= sec <= INT_FAST64_MAX
#endif

    typedef int_fast32_t xtime_nsec_t; //0 <= xtime.nsec < NANOSECONDS_PER_SECOND

    xtime_sec_t sec;
    xtime_nsec_t nsec;

    operator system_time() const
    {
        return mwboost::posix_time::from_time_t(0)+
            mwboost::posix_time::seconds(static_cast<long>(sec))+
#ifdef BOOST_DATE_TIME_HAS_NANOSECONDS
            mwboost::posix_time::nanoseconds(nsec);
#else
        mwboost::posix_time::microseconds((nsec+500)/1000);
#endif
    }

};

inline ::mwboost::xtime get_xtime(mwboost::system_time const& abs_time)
{
    ::mwboost::xtime res;
    mwboost::posix_time::time_duration const time_since_epoch=abs_time-mwboost::posix_time::from_time_t(0);

    res.sec=static_cast< ::mwboost::xtime::xtime_sec_t>(time_since_epoch.total_seconds());
    res.nsec=static_cast< ::mwboost::xtime::xtime_nsec_t>(time_since_epoch.fractional_seconds()*(1000000000/time_since_epoch.ticks_per_second()));
    return res;
}

inline int xtime_get(struct ::mwboost::xtime* xtp, int clock_type)
{
    if (clock_type == TIME_UTC_)
    {
        *xtp=get_xtime(get_system_time());
        return clock_type;
    }
    return 0;
}


inline int xtime_cmp(const ::mwboost::xtime& xt1, const ::mwboost::xtime& xt2)
{
    if (xt1.sec == xt2.sec)
        return (int)(xt1.nsec - xt2.nsec);
    else
        return (xt1.sec > xt2.sec) ? 1 : -1;
}

} // namespace mwboost

#include <boost/config/abi_suffix.hpp>
#endif
#endif //BOOST_XTIME_WEK070601_HPP

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
