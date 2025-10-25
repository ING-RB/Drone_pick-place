/* Copyright 2021 The MathWorks, Inc. */
#ifndef IHALIDE_DISCRETEFIR_HPP
#define IHALIDE_DISCRETEFIR_HPP

#include<stdint.h>

#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEDISCRETE_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEDISCRETE_API
#endif /*LIBMWHALIDEDISCRETE_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
#endif /*__cplusplus*/

LIBMWHALIDEDISCRETE_API void halideInit(int*);

LIBMWHALIDEDISCRETE_API void halideTBBInit(int *nGrainSize, int numChans, bool isTBBEnabled);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_RRD(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_RCD(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);


LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_CRD(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_CCD(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_RRS(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_RCS(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_CRS(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

LIBMWHALIDEDISCRETE_API void processHalide_discreteFIR_CCS(
	const void *fIn,
	const void *fCoeff,
	uint32_t frameLen,
	uint32_t coeffLen,
	uint32_t num_channels,
	void *fStates,
	void *fOut,
	void *fContextBuffer,
	int tbbGrainSize);

#ifdef __cplusplus
}
#endif /*__cplusplus*/

#endif /*IHALIDE_DISCRETEFIR_RRD_HPP*/
