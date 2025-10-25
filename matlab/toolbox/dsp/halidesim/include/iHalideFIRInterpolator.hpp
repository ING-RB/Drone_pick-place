/* Copyright 2021 The MathWorks, Inc. */
#ifndef IHALIDE_FIRINTERPOLATOR_HPP
#define IHALIDE_FIRINTERPOLATOR_HPP

#include<stdint.h>

#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEINTERPOLATOR_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEINTERPOLATOR_API
#endif /*LIBMWHALIDEDISCRETE_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
#endif /*__cplusplus */

LIBMWHALIDEINTERPOLATOR_API void halideTBBInit(int *nGrainSize, int numChans, bool isTBBEnabled);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorRRD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorRCD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);


LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorCRD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorCCD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorRRS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorRCS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorCRS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

LIBMWHALIDEINTERPOLATOR_API void processHalide_firInterpolatorCCS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int tbbGrainSize,
    int outIdx);

#ifdef __cplusplus
}
#endif /*IHALIDE_FIRINTERPOLATOR_HPP*/

#endif
