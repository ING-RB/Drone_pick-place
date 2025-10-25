/* Copyright 2023 The MathWorks, Inc. */

/**
 * @file
 * Utility macros for exporting 3p/vdbfusion's VDBVolume class on win64.
 */

#ifndef VDBFUSION_3P_UTIL_HPP_
#define VDBFUSION_3P_UTIL_HPP_

#ifdef _MSC_VER
	#define DLL_EXPORT_SYM __declspec(dllexport)
	#define DLL_IMPORT_SYM __declspec(dllimport)
#elif __GNUC__ >= 4
	#define DLL_EXPORT_SYM __attribute__ ((visibility("default")))
	#define DLL_IMPORT_SYM __attribute__ ((visibility("default")))
#else
	#define DLL_EXPORT_SYM
	#define DLL_IMPORT_SYM
#endif /* _MSC_VER */

#if defined(BUILDING_VDBFUSION_3P)
/* For dll import/export symbols */
	#define VDBFUSION_3P_API DLL_EXPORT_SYM
#else
	#define VDBFUSION_3P_API DLL_IMPORT_SYM
#endif

#endif /* VDBFUSION_3P_UTIL_HPP_ */
