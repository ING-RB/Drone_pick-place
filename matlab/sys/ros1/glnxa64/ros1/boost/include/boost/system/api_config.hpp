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

//  boost/system/api_config.hpp  -------------------------------------------------------//

//  Copyright Beman Dawes 2003, 2006, 2010

//  Distributed under the Boost Software License, Version 1.0.
//  See http://www.boost.org/LICENSE_1_0.txt

//  See http://www.boost.org/libs/system for documentation.

//--------------------------------------------------------------------------------------//

//  Boost.System calls operating system API functions to implement system error category
//  functions. Usually there is no question as to which API is to be used.
//
//  In the case of MinGW or Cygwin/MinGW, however, both POSIX and Windows API's are
//  available. Chaos ensues if other code thinks one is in use when Boost.System was
//  actually built with the other. This header centralizes the API choice and prevents
//  user definition of API macros, thus elminating the possibility of mismatches and the
//  need to test configurations with little or no practical value.
//

//--------------------------------------------------------------------------------------//

#ifndef BOOST_SYSTEM_API_CONFIG_HPP                  
#define BOOST_SYSTEM_API_CONFIG_HPP

# if defined(BOOST_POSIX_API) || defined(BOOST_WINDOWS_API)
#   error user defined BOOST_POSIX_API or BOOST_WINDOWS_API not supported
# endif

//  BOOST_POSIX_API or BOOST_WINDOWS_API specify which API to use
//    Cygwin/MinGW does not predefine _WIN32.
//    Standalone MinGW and all other known Windows compilers do predefine _WIN32
//    Compilers that predefine _WIN32 or __MINGW32__ do so for Windows 64-bit builds too.

# if defined(_WIN32) || defined(__CYGWIN__) // Windows default, including MinGW and Cygwin
#   define BOOST_WINDOWS_API
# else
#   define BOOST_POSIX_API 
# endif
                                     
#endif  // BOOST_SYSTEM_API_CONFIG_HPP 

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
