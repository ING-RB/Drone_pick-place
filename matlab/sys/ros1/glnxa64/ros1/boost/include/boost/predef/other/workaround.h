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
Copyright Rene Rivera 2017
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#ifndef BOOST_PREDEF_WORKAROUND_H
#define BOOST_PREDEF_WORKAROUND_H

/* tag::reference[]

= `BOOST_PREDEF_WORKAROUND`

[source]
----
BOOST_PREDEF_WORKAROUND(symbol,comp,major,minor,patch)
----

Usage:

[source]
----
#if BOOST_PREDEF_WORKAROUND(BOOST_COMP_CLANG,<,3,0,0)
    // Workaround for old clang compilers..
#endif
----

Defines a comparison against two version numbers that depends on the definion
of `BOOST_STRICT_CONFIG`. When `BOOST_STRICT_CONFIG` is defined this will expand
to a value convertible to `false`. Which has the effect of disabling all code
conditionally guarded by `BOOST_PREDEF_WORKAROUND`. When `BOOST_STRICT_CONFIG`
is undefine this expand to test the given `symbol` version value with the
`comp` comparison against `BOOST_VERSION_NUMBER(major,minor,patch)`.

*/ // end::reference[]
#ifdef BOOST_STRICT_CONFIG
#   define BOOST_PREDEF_WORKAROUND(symbol, comp, major, minor, patch) (0)
#else
#   include <boost/predef/version_number.h>
#   define BOOST_PREDEF_WORKAROUND(symbol, comp, major, minor, patch) \
        ( (symbol) != (0) ) && \
        ( (symbol) comp (BOOST_VERSION_NUMBER( (major) , (minor) , (patch) )) )
#endif

/* tag::reference[]

= `BOOST_PREDEF_TESTED_AT`

[source]
----
BOOST_PREDEF_TESTED_AT(symbol,major,minor,patch)
----

Usage:

[source]
----
#if BOOST_PREDEF_TESTED_AT(BOOST_COMP_CLANG,3,5,0)
    // Needed for clang, and last checked for 3.5.0.
#endif
----

Defines a comparison against two version numbers that depends on the definion
of `BOOST_STRICT_CONFIG` and `BOOST_DETECT_OUTDATED_WORKAROUNDS`.
When `BOOST_STRICT_CONFIG` is defined this will expand to a value convertible
to `false`. Which has the effect of disabling all code
conditionally guarded by `BOOST_PREDEF_TESTED_AT`. When `BOOST_STRICT_CONFIG`
is undefined this expand to either:

* A value convertible to `true` when `BOOST_DETECT_OUTDATED_WORKAROUNDS` is not
  defined.
* A value convertible `true` when the expansion of
  `BOOST_PREDEF_WORKAROUND(symbol, <=, major, minor, patch)` is `true` and
  `BOOST_DETECT_OUTDATED_WORKAROUNDS` is defined.
* A compile error when the expansion of
  `BOOST_PREDEF_WORKAROUND(symbol, >, major, minor, patch)` is true and
  `BOOST_DETECT_OUTDATED_WORKAROUNDS` is defined.

*/ // end::reference[]
#ifdef BOOST_STRICT_CONFIG
#   define BOOST_PREDEF_TESTED_AT(symbol, major, minor, patch) (0)
#else
#   ifdef BOOST_DETECT_OUTDATED_WORKAROUNDS
#       define BOOST_PREDEF_TESTED_AT(symbol, major, minor, patch) ( \
            BOOST_PREDEF_WORKAROUND(symbol, <=, major, minor, patch) \
            ? 1 \
            : (1%0) )
#   else
#       define BOOST_PREDEF_TESTED_AT(symbol, major, minor, patch) \
            ( (symbol) >= BOOST_VERSION_NUMBER_AVAILABLE )
#   endif
#endif

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
