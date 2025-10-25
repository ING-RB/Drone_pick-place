/* Copyright 2021 The MathWorks, Inc. */
#ifndef IHALIDE_FIRPOLYPHASEFFTSYNTHESIS_HPP
#define IHALIDE_FIRPOLYPHASEFFTSYNTHESIS_HPP

#include<stdint.h>

#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDESYNTHESIS_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDESYNTHESIS_API
#endif /*LIBMWHALIDEDISCRETE_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
#endif /*__cplusplus */

LIBMWHALIDESYNTHESIS_API void processHalide_firPolyphaseFFTSynthesis_RRS(
    const void *vIn,
    const void *vCoeff,
    void *vOut,
    void *vStates,
    void *vContextBuffer,
    uint32_t inputLen,
    uint32_t inputNumBands,
    uint32_t interpFactor,
    uint32_t numChannels,
    uint32_t polyPhaseLen);

LIBMWHALIDESYNTHESIS_API void processHalide_firPolyphaseFFTSynthesis_RRD(
    const void *vIn,
    const void *vCoeff,
    void *vOut,
    void *vStates,
    void *vContextBuffer,
    uint32_t inputLen,
    uint32_t inputNumBands,
    uint32_t interpFactor,
    uint32_t numChannels,
    uint32_t polyPhaseLen);

LIBMWHALIDESYNTHESIS_API void processHalide_firPolyphaseFFTSynthesis_CRS(
    const void *vIn,
    const void *vCoeff,
    void *vOut,
    void *vStates,
    void *vContextBuffer,
    uint32_t inputLen,
    uint32_t inputNumBands,
    uint32_t interpFactor,
    uint32_t numChannels,
    uint32_t polyPhaseLen);

LIBMWHALIDESYNTHESIS_API void processHalide_firPolyphaseFFTSynthesis_CRD(
    const void *vIn,
    const void *vCoeff,
    void *vOut,
    void *vStates,
    void *vContextBuffer,
    uint32_t inputLen,
    uint32_t inputNumBands,
    uint32_t interpFactor,
    uint32_t numChannels,
    uint32_t polyPhaseLen);

LIBMWHALIDESYNTHESIS_API void processHalide_firPolyphaseFFTSynthesis_CCS(
    const void *vIn,
    const void *vCoeff,
    void *vOut,
    void *vStates,
    void *vContextBuffer,
    uint32_t inputLen,
    uint32_t inputNumBands,
    uint32_t interpFactor,
    uint32_t numChannels,
    uint32_t polyPhaseLen);

LIBMWHALIDESYNTHESIS_API void processHalide_firPolyphaseFFTSynthesis_CCD(
    const void *vIn,
    const void *vCoeff,
    void *vOut,
    void *vStates,
    void *vContextBuffer,
    uint32_t inputLen,
    uint32_t inputNumBands,
    uint32_t interpFactor,
    uint32_t numChannels,
    uint32_t polyPhaseLen);

#ifdef __cplusplus
}
#endif /*IHALIDE_FIRPOLYPHASEFFTSYNTHESIS_HPP*/

#endif
