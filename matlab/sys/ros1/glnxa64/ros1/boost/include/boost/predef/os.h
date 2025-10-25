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
Copyright Franz Detro 2014
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#if !defined(BOOST_PREDEF_OS_H) || defined(BOOST_PREDEF_INTERNAL_GENERATE_TESTS)
#ifndef BOOST_PREDEF_OS_H
#define BOOST_PREDEF_OS_H
#endif

#include <boost/predef/os/aix.h>
#include <boost/predef/os/amigaos.h>
#include <boost/predef/os/beos.h>
#include <boost/predef/os/bsd.h>
#include <boost/predef/os/cygwin.h>
#include <boost/predef/os/haiku.h>
#include <boost/predef/os/hpux.h>
#include <boost/predef/os/irix.h>
#include <boost/predef/os/ios.h>
#include <boost/predef/os/linux.h>
#include <boost/predef/os/macos.h>
#include <boost/predef/os/os400.h>
#include <boost/predef/os/qnxnto.h>
#include <boost/predef/os/solaris.h>
#include <boost/predef/os/unix.h>
#include <boost/predef/os/vms.h>
#include <boost/predef/os/windows.h>

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
