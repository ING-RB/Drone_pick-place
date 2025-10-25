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

#if !defined(BOOST_PREDEF_COMPILER_H) || defined(BOOST_PREDEF_INTERNAL_GENERATE_TESTS)
#ifndef BOOST_PREDEF_COMPILER_H
#define BOOST_PREDEF_COMPILER_H
#endif

#include <boost/predef/compiler/borland.h>
#include <boost/predef/compiler/clang.h>
#include <boost/predef/compiler/comeau.h>
#include <boost/predef/compiler/compaq.h>
#include <boost/predef/compiler/diab.h>
#include <boost/predef/compiler/digitalmars.h>
#include <boost/predef/compiler/dignus.h>
#include <boost/predef/compiler/edg.h>
#include <boost/predef/compiler/ekopath.h>
#include <boost/predef/compiler/gcc_xml.h>
#include <boost/predef/compiler/gcc.h>
#include <boost/predef/compiler/greenhills.h>
#include <boost/predef/compiler/hp_acc.h>
#include <boost/predef/compiler/iar.h>
#include <boost/predef/compiler/ibm.h>
#include <boost/predef/compiler/intel.h>
#include <boost/predef/compiler/kai.h>
#include <boost/predef/compiler/llvm.h>
#include <boost/predef/compiler/metaware.h>
#include <boost/predef/compiler/metrowerks.h>
#include <boost/predef/compiler/microtec.h>
#include <boost/predef/compiler/mpw.h>
#include <boost/predef/compiler/nvcc.h>
#include <boost/predef/compiler/palm.h>
#include <boost/predef/compiler/pgi.h>
#include <boost/predef/compiler/sgi_mipspro.h>
#include <boost/predef/compiler/sunpro.h>
#include <boost/predef/compiler/tendra.h>
#include <boost/predef/compiler/visualc.h>
#include <boost/predef/compiler/watcom.h>

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
