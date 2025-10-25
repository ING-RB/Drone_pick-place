/* Copyright 2021-2022 The MathWorks, Inc. */
#ifndef IHALIDE_POLYPHASEANALYSIS_HPP
#define IHALIDE_POLYPHASEANALYSIS_HPP

#include <stdint.h>
#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEANALYSIS_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEANALYSIS_API
#endif /*LIBMWHALIDEANALYSIS_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
    #endif /*__cplusplus */

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisRRD(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisRRS(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisRCD(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisRCS(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisCRD(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisCRS(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisCCD(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    LIBMWHALIDEANALYSIS_API void processHalide_PolyphaseAnalysisCCS(
        const void *px,
        const void *pp,
        void *pz,
        void *pvBuff,
        void *pv,
        uint32_t Lx,
        uint32_t Np,
        uint32_t N,
        uint32_t M,
        uint32_t D,
        uint32_t K,
        int32_t *phaseIndex,
        int32_t *currentState,
        uint32_t outputLen);

    #ifdef __cplusplus
}
#endif /*IHALIDE_POLYPHASEANALYSIS_HPP*/

#endif
