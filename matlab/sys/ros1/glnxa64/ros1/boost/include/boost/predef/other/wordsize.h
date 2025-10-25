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
Copyright Rene Ferdinand Rivera Morell 2020-2021
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#ifndef BOOST_PREDEF_OTHER_WORD_SIZE_H
#define BOOST_PREDEF_OTHER_WORD_SIZE_H

#include <boost/predef/architecture.h>
#include <boost/predef/version_number.h>
#include <boost/predef/make.h>

/* tag::reference[]
= `BOOST_ARCH_WORD_BITS`

Detects the native word size, in bits, for the current architecture. There are
two types of macros for this detection:

* `BOOST_ARCH_WORD_BITS`, gives the number of word size bits
  (16, 32, 64).
* `BOOST_ARCH_WORD_BITS_16`, `BOOST_ARCH_WORD_BITS_32`, and
  `BOOST_ARCH_WORD_BITS_64`, indicate when the given word size is
  detected.

They allow for both single checks and direct use of the size in code.

NOTE: The word size is determined manually on each architecture. Hence use of
the `wordsize.h` header will also include all the architecture headers.

*/ // end::reference[]

#if !defined(BOOST_ARCH_WORD_BITS_64)
#   define BOOST_ARCH_WORD_BITS_64 BOOST_VERSION_NUMBER_NOT_AVAILABLE
#elif !defined(BOOST_ARCH_WORD_BITS)
#   define BOOST_ARCH_WORD_BITS 64
#endif

#if !defined(BOOST_ARCH_WORD_BITS_32)
#   define BOOST_ARCH_WORD_BITS_32 BOOST_VERSION_NUMBER_NOT_AVAILABLE
#elif !defined(BOOST_ARCH_WORD_BITS)
#	  define BOOST_ARCH_WORD_BITS 32
#endif

#if !defined(BOOST_ARCH_WORD_BITS_16)
#   define BOOST_ARCH_WORD_BITS_16 BOOST_VERSION_NUMBER_NOT_AVAILABLE
#elif !defined(BOOST_ARCH_WORD_BITS)
#   define BOOST_ARCH_WORD_BITS 16
#endif

#if !defined(BOOST_ARCH_WORD_BITS)
#   define BOOST_ARCH_WORD_BITS 0
#endif

#define BOOST_ARCH_WORD_BITS_NAME "Word Bits"
#define BOOST_ARCH_WORD_BITS_16_NAME "16-bit Word Size"
#define BOOST_ARCH_WORD_BITS_32_NAME "32-bit Word Size"
#define BOOST_ARCH_WORD_BITS_64_NAME "64-bit Word Size"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_WORD_BITS,BOOST_ARCH_WORD_BITS_NAME)

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_WORD_BITS_16,BOOST_ARCH_WORD_BITS_16_NAME)

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_WORD_BITS_32,BOOST_ARCH_WORD_BITS_32_NAME)

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_WORD_BITS_64,BOOST_ARCH_WORD_BITS_64_NAME)

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
