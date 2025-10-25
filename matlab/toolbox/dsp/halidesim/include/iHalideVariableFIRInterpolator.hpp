/* Copyright 2022-2023 The MathWorks, Inc. */
#ifndef IHALIDE_VARIABLEFIRINTERPOLATOR_HPP
#define IHALIDE_VARIABLEFIRINTERPOLATOR_HPP

#include<stdint.h>

#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEVARIABLEINTERPOLATOR_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEVARIABLEINTERPOLATOR_API
#endif /*LIBMWHALIDEVARIABLEINTERPOLATOR_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
#endif /*__cplusplus */

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorRRD(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorRRS(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorRCD(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorRCS(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorCRD(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorCRS(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorCCD(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

LIBMWHALIDEVARIABLEINTERPOLATOR_API void processHalide_variableFirInterpolatorCCS(/* sbcheck:ok:extern_c needed*/
    const void *vIn,
    const void *vCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t num_channels,
    uint32_t interpolationFactor,
    uint32_t maxInterpolationFactor,
    int32_t *polyphaseSelector,
    void *vStates,
    void *vOut);

#ifdef __cplusplus
}
#endif /*IHALIDE_FIRINTERPOLATOR_HPP*/

#endif