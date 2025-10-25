/* Copyright 2018-2020 The MathWorks, Inc. */
#ifndef __CPP11_WARNING_H
#define __CPP11_WARNING_H 1

#if _MSC_VER < 1900
#if __cplusplus < 201103L
#  warning This Polyspace internal file is used because you have #include-s to one or more headers that require compilation with the ISO C++ 2011 (C++11) standard. Use the Polyspace analysis option -cpp-version cpp11 to enable C++11 support.
#endif
#endif

#endif
