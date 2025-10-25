/* Copyright 2021-2022 The MathWorks, Inc. */
#ifndef IHALIDE_FREQUENCYDOMAINFIRFILTER_HPP
#define IHALIDE_FREQUENCYDOMAINFIRFILTER_HPP

#include<stdint.h>
#if defined(BUILDING_HALIDEDSPLIBS)
#include "version.h"
#define LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API DLL_EXPORT_SYM
#else
#define LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API
#endif /*LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API*/

#ifdef __cplusplus
extern "C" { /* sbcheck:ok:extern_c needed */
    #endif /*__cplusplus */

    LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API void processHalide_FDFIR_NoPartitionOS_CCS(
        const void *vIn,
        const void *vCoeff,
        uint32_t fftLength,
        uint32_t numChannels,
        void *vOut);

    LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API void processHalide_FDFIR_NoPartitionOS_CCD(
        const void *vIn,
        const void *vCoeff,
        uint32_t fftLength,
        uint32_t numChannels,
        void *vOut);

    LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API void processHalide_FDFIR_NoPartitionOA_CCS(
        const void *vIn,
        const void *vCoeff,
        uint32_t fftLength,
        uint32_t numFrames,
        uint32_t numChannels,
        void *vOut);

    LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API void processHalide_FDFIR_NoPartitionOA_CCD(
        const void *vIn,
        const void *vCoeff,
        uint32_t fftLength,
        uint32_t numFrames,
        uint32_t numChannels,
        void *vOut);

    LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API void processHalide_FDFIR_PartitionOAOS_CCS(
        const void *vIn,
        const void *vCoeff,
        uint32_t fftLength,
        uint32_t numPartitions,
        uint32_t numChannels,
        void *vOut);

    LIBMWHALIDEFREQUENCYDOMAINFIRFILTER_API void processHalide_FDFIR_PartitionOAOS_CCD(
        const void *vIn,
        const void *vCoeff,
        uint32_t fftLength,
        uint32_t numPartitions,
        uint32_t numChannels,
        void *vOut);
    #ifdef __cplusplus
}
#endif /*__cplusplus*/

#endif /*IHALIDE_FREQUENCYDOMAINFIRFILTER_HPP*/
