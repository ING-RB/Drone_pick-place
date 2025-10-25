/* Copyright 2022-2023 The MathWorks, Inc. */
#ifndef IHALIDE_VARIABLEFIRDECIMATOR_HPP
#define IHALIDE_VARIABLEFIRDECIMATOR_HPP

#include<stdint.h>
 
#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEVARIABLEDECIMATOR_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEVARIABLEDECIMATOR_API
#endif /*LIBMWHALIDEVARIABLEDECIMATOR_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
    #endif /*__cplusplus */

    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorRRD(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorRRS(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorRCD(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorRCS(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorCRD(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorCRS(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorCCD(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);
    
    LIBMWHALIDEVARIABLEDECIMATOR_API void processHalide_variableFIRDecimatorCCS(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        void *vbuffer,
        const void *vCoeff,
        uint32_t decimMax,
        uint32_t decimFactor,
        uint32_t inputLen,
        uint32_t numChannels,
        uint32_t statesLength,
        uint32_t bufferLength,
        uint32_t polyphaseCoeffLen,
        uint32_t outputLen,
        void* accumulator,
        uint32_t* commPhase,
        void *vStates,
        void *vOut);

    #ifdef __cplusplus
}
#endif /*__cplusplus*/

#endif/*IHALIDE_VARIABLEFIRDECIMATOR_HPP*/