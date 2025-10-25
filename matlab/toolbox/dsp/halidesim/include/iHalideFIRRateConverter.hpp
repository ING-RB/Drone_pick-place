/* Copyright 2021 The MathWorks, Inc. */
#ifndef IHALIDE_FIRRATECONVERTER_HPP
#define IHALIDE_FIRRATECONVERTER_HPP

#include<stdint.h>

#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEFIRRATECONVERTER_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEFIRRATECONVERTER_API
#endif /*LIBMWHALIDEFIRRATECONVERTER_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
#endif /*__cplusplus */

LIBMWHALIDEFIRRATECONVERTER_API void halideInit(int* ret);

LIBMWHALIDEFIRRATECONVERTER_API void halideTBBInit(int *nGrainSize, int numChans, bool isTBBEnabled);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterRRD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterRCD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);


LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterCRD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterCCD(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterRRS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterRCS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterCRS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

LIBMWHALIDEFIRRATECONVERTER_API void processHalide_firRateConverterCCS(
    const void *fIn,
    const void *fCoeff,
    uint32_t frameLen,
    uint32_t polyphaseCoeffLen,
    uint32_t numChannels,
    uint32_t interpolationFactor,
    uint32_t decimationFactor,
    const int32_t *indexSelector,
    const int32_t *polyphaseSelector,
    void *fStates,
    void *fOut,
    void *fContextBuffer,
    int32_t tbbGrainSize,
    uint32_t outputLen,
    uint32_t *phaseIdx,
    uint32_t *utilizedPs,
    bool isMultiRate);

#ifdef __cplusplus
}
#endif /*IHALIDE_FIRRATECONVERTER_HPP*/

#endif
