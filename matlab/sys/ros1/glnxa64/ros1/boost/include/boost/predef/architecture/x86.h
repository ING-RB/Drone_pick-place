#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(__GNUC__)
#    pragma GCC system_header
#  elif defined(_MSC_VER)
     /* The matching "pop" is in header_suffix.h */
#    pragma warning(push, 1)
       /*
        * These suppressions are only here because of the apparent compiler bug:
        * http://komodo.mathworks.com/main/gecko?Action=view&Record=g782945
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

/*
Copyright Rene Rivera 2008-2015
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#include <boost/predef/architecture/x86/32.h>
#include <boost/predef/architecture/x86/64.h>

#ifndef BOOST_PREDEF_ARCHITECTURE_X86_H
#define BOOST_PREDEF_ARCHITECTURE_X86_H

/* tag::reference[]
= `BOOST_ARCH_X86`

http://en.wikipedia.org/wiki/X86[Intel x86] architecture. This is
a category to indicate that either `BOOST_ARCH_X86_32` or
`BOOST_ARCH_X86_64` is detected.
*/ // end::reference[]

#define BOOST_ARCH_X86 BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if BOOST_ARCH_X86_32 || BOOST_ARCH_X86_64
#   undef BOOST_ARCH_X86
#   define BOOST_ARCH_X86 BOOST_VERSION_NUMBER_AVAILABLE
#endif

#if BOOST_ARCH_X86
#   define BOOST_ARCH_X86_AVAILABLE
#endif

#define BOOST_ARCH_X86_NAME "Intel x86"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_X86,BOOST_ARCH_X86_NAME)

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
