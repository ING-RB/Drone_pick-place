//  Copyright 2015-2019 The MathWorks, Inc.

#ifndef AMCL_EXPORTS_H
#define AMCL_EXPORTS_H

#ifdef _WIN32
#ifdef LIBRARY_EXPORTS
#define LIBRARY_API __declspec(dllexport)
#else
#define LIBRARY_API __declspec(dllimport)
#endif
#else
#define LIBRARY_API
#endif

#endif