/* Copyright 2017-2020 The MathWorks, Inc. */
// -*- C++ -*-
//===--------------------------- stdbool.h --------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is dual licensed under the MIT and the University of Illinois Open
// Source Licenses. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef _LIBCPP_STDBOOL_H
#define _LIBCPP_STDBOOL_H


/*
    stdbool.h synopsis

Macros:

    __bool_true_false_are_defined

*/

#include <__config>

#if !defined(_LIBCPP_HAS_NO_PRAGMA_SYSTEM_HEADER)
#pragma GCC system_header
#endif

#include_next <stdbool.h>

#ifdef __cplusplus

#if defined __GNUC__
/* Supporting _Bool in C++ is a GCC extension.  */
#define _Bool   bool
#endif /* defined __GNUC__ */

#if defined __GNUC__ && __cplusplus < 201103L
/* Defining these macros in C++98 is a GCC extension.  */
#define bool    bool
#define false   false
#define true    true
#else
#undef bool
#undef true
#undef false
#endif /* defined __GNUC__ && __cplusplus < 201103L */

#undef __bool_true_false_are_defined
#define __bool_true_false_are_defined 1

#endif /* __cplusplus */

#endif  // _LIBCPP_STDBOOL_H
