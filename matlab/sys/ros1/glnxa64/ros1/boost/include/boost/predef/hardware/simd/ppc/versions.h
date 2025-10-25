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
Copyright Charly Chevalier 2015
Copyright Joel Falcou 2015
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#ifndef BOOST_PREDEF_HARDWARE_SIMD_PPC_VERSIONS_H
#define BOOST_PREDEF_HARDWARE_SIMD_PPC_VERSIONS_H

#include <boost/predef/version_number.h>

/* tag::reference[]
= `BOOST_HW_SIMD_PPC_*_VERSION`

Those defines represent Power PC SIMD extensions versions.

NOTE: You *MUST* compare them with the predef `BOOST_HW_SIMD_PPC`.
*/ // end::reference[]

// ---------------------------------

/* tag::reference[]
= `BOOST_HW_SIMD_PPC_VMX_VERSION`

The https://en.wikipedia.org/wiki/AltiVec#VMX128[VMX] powerpc extension
version number.

Version number is: *1.0.0*.
*/ // end::reference[]
#define BOOST_HW_SIMD_PPC_VMX_VERSION BOOST_VERSION_NUMBER(1, 0, 0)

/* tag::reference[]
= `BOOST_HW_SIMD_PPC_VSX_VERSION`

The https://en.wikipedia.org/wiki/AltiVec#VSX[VSX] powerpc extension version
number.

Version number is: *1.1.0*.
*/ // end::reference[]
#define BOOST_HW_SIMD_PPC_VSX_VERSION BOOST_VERSION_NUMBER(1, 1, 0)

/* tag::reference[]
= `BOOST_HW_SIMD_PPC_QPX_VERSION`

The QPX powerpc extension version number.

Version number is: *2.0.0*.
*/ // end::reference[]
#define BOOST_HW_SIMD_PPC_QPX_VERSION BOOST_VERSION_NUMBER(2, 0, 0)

/* tag::reference[]

*/ // end::reference[]

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
