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

//  boost/chrono/thread_clock.hpp  -----------------------------------------------------------//

//  Copyright 2009-2011 Vicente J. Botet Escriba

//  Distributed under the Boost Software License, Version 1.0.
//  See http://www.boost.org/LICENSE_1_0.txt

//  See http://www.boost.org/libs/system for documentation.

#include <boost/chrono/config.hpp>

#ifndef BOOST_CHRONO_THREAD_CLOCK_HPP
#define BOOST_CHRONO_THREAD_CLOCK_HPP

#if defined(BOOST_CHRONO_HAS_THREAD_CLOCK)

#include <boost/chrono/config.hpp>
#include <boost/chrono/duration.hpp>
#include <boost/chrono/time_point.hpp>
#include <boost/chrono/detail/system.hpp>
#include <boost/chrono/clock_string.hpp>

#ifndef BOOST_CHRONO_HEADER_ONLY
#include <boost/config/abi_prefix.hpp> // must be the last #include
#endif

namespace mwboost {} namespace boost = mwboost; namespace mwboost { namespace chrono {

class BOOST_CHRONO_DECL thread_clock {
public:
    typedef nanoseconds                          duration;
    typedef duration::rep                        rep;
    typedef duration::period                     period;
    typedef chrono::time_point<thread_clock>    time_point;
    BOOST_STATIC_CONSTEXPR bool is_steady =             BOOST_CHRONO_THREAD_CLOCK_IS_STEADY;

    static BOOST_CHRONO_INLINE time_point now( ) BOOST_NOEXCEPT;
#if !defined BOOST_CHRONO_DONT_PROVIDE_HYBRID_ERROR_HANDLING
    static BOOST_CHRONO_INLINE time_point now( system::error_code & ec );
#endif
};

template <class CharT>
struct clock_string<thread_clock, CharT>
{
  static std::basic_string<CharT> name()
  {
    static const CharT u[] =
    { 't', 'h', 'r', 'e', 'a', 'd', '_',
      'c', 'l','o', 'c', 'k'};
    static const std::basic_string<CharT> str(u, u + sizeof(u)/sizeof(u[0]));
    return str;
  }
  static std::basic_string<CharT> since()
  {
    const CharT u[] =
    { ' ', 's', 'i', 'n', 'c', 'e', ' ', 't', 'h', 'r', 'e', 'a', 'd', ' ', 's', 't', 'a', 'r', 't', '-', 'u', 'p'};
    const std::basic_string<CharT> str(u, u + sizeof(u)/sizeof(u[0]));
    return str;
  }
};

} // namespace chrono
} // namespace mwboost


#ifndef BOOST_CHRONO_HEADER_ONLY
#include <boost/config/abi_suffix.hpp> // pops abi_prefix.hpp pragmas
#else
#include <boost/chrono/detail/inlined/thread_clock.hpp>
#endif

#endif

#endif  // BOOST_CHRONO_THREAD_CLOCK_HPP

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
