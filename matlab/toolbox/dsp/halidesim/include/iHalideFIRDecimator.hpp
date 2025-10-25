/* Copyright 2021 The MathWorks, Inc. */
#ifndef IHALIDE_FIRDECIMATOR_HPP
#define IHALIDE_FIRDECIMATOR_HPP

#include <stdint.h>
#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEDECIMATOR_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEDECIMATOR_API
#endif /*LIBMWHALIDEDECIMATOR_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
    #endif /*__cplusplus */

    LIBMWHALIDEDECIMATOR_API void halideTBBInit(int *nGrainSize, int numChans, bool isTBBEnabled);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorRRD(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorRCD(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);


    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorCRD(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorCCD(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorRRS(/* sbcheck:ok:extern_c needed*/
        const void *vIn,
        const void *vCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *vStates,
        void *vOut,
        void *vContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorRCS(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorCRS(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    LIBMWHALIDEDECIMATOR_API void processHalide_firDecimatorCCS(
        const void *fIn,
        const void *fCoeff,
        uint32_t frameLen,
        uint32_t polyphaseCoeffLen,
        uint32_t num_channels,
        uint32_t decimFactor,
        void *fStates,
        void *fOut,
        void *fContextBuffer,
        void *vAccumulator,
        int32_t* phaseIdx,
        int32_t* cffIdx,
        int32_t* pS,
        uint32_t* outIdx,
        bool isMultirate,
        bool isInputOffset,
        int tbbGrainSize);

    #ifdef __cplusplus
}
#endif /*IHALIDE_FIRDECIMATOR_HPP*/

#endif
