/* Copyright 2019-2024 The MathWorks, Inc. */
#ifndef __MW_CUDAIMHIST_UTIL_H__
#define __MW_CUDAIMHIST_UTIL_H__

#include "rtwtypes.h"

#ifdef __CUDACC__

#define MWDEVICE_INLINE __device__ __inline__
#define MW_HOST_DEVICE  __host__ __device__

#define SHARED_MEMORY_THREADS 512

namespace {
template <class T>
MWDEVICE_INLINE unsigned int getIndex(T value, unsigned int nbins, double range, double offset) {
    double scale = (double)(nbins - 1) / range;
    return min(nbins - 1, (unsigned int)((value + offset) * scale + 0.5));
}

// double
template <>
MWDEVICE_INLINE unsigned int getIndex(double value,
                                      unsigned int nbins,
                                      double /*range*/,
                                      double /*offset*/) {
    if (isnan(value)) {
        return 0;
    }

    return max(0, min(nbins - 1, (unsigned int)floor(value * (nbins - 1) + 0.5)));
}

// single
template <>
MWDEVICE_INLINE unsigned int getIndex(float value,
                                      unsigned int nbins,
                                      double /*range*/,
                                      double /*offset*/) {
    if (isnan(value)) {
        return 0;
    }

    return max(0, min(nbins - 1, (unsigned int)floor((double)value * (nbins - 1) + 0.5)));
}

template <class T>
MWDEVICE_INLINE unsigned int getIndexCmap(T value, unsigned int nbins) {
    unsigned int location = (unsigned int)((double)value);
    if (location > (unsigned int)nbins - 1) {
        location = (unsigned int)nbins - 1;
    }
    return location;
}

// for floating point types, indices start at 1
template <>
MWDEVICE_INLINE unsigned int getIndexCmap(double value, unsigned int nbins) {
    if (isnan(value)) {
        return 0;
    }

    unsigned int location = (unsigned int)value - 1;
    if (location > (unsigned int)nbins) {
        location = (unsigned int)nbins;
    }
    return location;
}

template <>
MWDEVICE_INLINE unsigned int getIndexCmap(float value, unsigned int nbins) {
    if (isnan(value)) {
        return 0;
    }

    unsigned int location = (unsigned int)value - 1;
    if (location > (unsigned int)nbins) {
        location = (unsigned int)nbins;
    }
    return location;
}

MWDEVICE_INLINE real_T extractData(real_T value) {
    return value;
}
MWDEVICE_INLINE uint8_T extractData(uint8_T value) {
    return value;
}
MWDEVICE_INLINE uint16_T extractData(uint16_T value) {
    return value;
}
MWDEVICE_INLINE uint32_T extractData(uint32_T value) {
    return value;
}
MWDEVICE_INLINE int8_T extractData(int8_T value) {
    return value;
}
MWDEVICE_INLINE int16_T extractData(int16_T value) {
    return value;
}
MWDEVICE_INLINE int32_T extractData(int32_T value) {
    return value;
}

MWDEVICE_INLINE real_T extractData(creal_T value) {
    return value.re;
}
MWDEVICE_INLINE uint8_T extractData(cuint8_T value) {
    return value.re;
}
MWDEVICE_INLINE uint16_T extractData(cuint16_T value) {
    return value.re;
}
MWDEVICE_INLINE uint32_T extractData(cuint32_T value) {
    return value.re;
}
MWDEVICE_INLINE int8_T extractData(cint8_T value) {
    return value.re;
}
MWDEVICE_INLINE int16_T extractData(cint16_T value) {
    return value.re;
}
MWDEVICE_INLINE int32_T extractData(cint32_T value) {
    return value.re;
}
} // namespace

template <class T>
__global__ void imhist_sm(const T* I,
                          unsigned int* counts,
                          double nelements,
                          double nbins,
                          double range,
                          double offset) {
    const unsigned int id = (blockIdx.x * blockDim.x) + threadIdx.x;
    const unsigned int stride = blockDim.x * gridDim.x;

    extern __shared__ unsigned int blockCounts[];

    for (unsigned int i = threadIdx.x; i < nbins; i += blockDim.x) {
        blockCounts[i] = 0;
    }

    __syncthreads();

    for (unsigned int i = id; i < nelements; i += stride) {
        unsigned int location = getIndex(extractData(I[i]), nbins, range, offset);
        atomicAdd(blockCounts + location, 1);
    }

    __syncthreads();

    for (unsigned int i = threadIdx.x; i < nbins; i += blockDim.x) {
        atomicAdd(counts + i, blockCounts[i]);
    }
}

template <class T>
__global__ void imhist_sm_cmap(const T* I, unsigned int* counts, double nelements, double nbins) {
    const unsigned int id = (blockIdx.x * blockDim.x) + threadIdx.x;
    const unsigned int stride = blockDim.x * gridDim.x;

    extern __shared__ unsigned int blockCounts[];

    for (unsigned int i = threadIdx.x; i < nbins; i += blockDim.x) {
        blockCounts[i] = 0;
    }

    __syncthreads();

    for (unsigned int i = id; i < nelements; i += stride) {
        unsigned int location = getIndexCmap(extractData(I[i]), nbins);
        atomicAdd(blockCounts + location, 1);
    }

    __syncthreads();

    for (unsigned int i = threadIdx.x; i < nbins; i += blockDim.x) {
        atomicAdd(counts + i, blockCounts[i]);
    }
}

template <class T>
void gpu_imhist_numeric(const T* I,
                        unsigned int* counts,
                        double nelements,
                        double nbins,
                        double range,
                        double offset) {
    unsigned int bufferSize = sizeof(unsigned int) * nbins;
    unsigned int threads = SHARED_MEMORY_THREADS;
    unsigned int blocks = min((unsigned int)(nelements + threads - 1) / threads, 500);

    imhist_sm<<<blocks, threads, bufferSize>>>(I, counts, nelements, nbins, range, offset);
}

template <class T>
void gpu_imhist_cmap(const T* I, unsigned int* counts, double nelements, double nbins) {
    unsigned int bufferSize = sizeof(unsigned int) * nbins;
    unsigned int threads = SHARED_MEMORY_THREADS;
    unsigned int blocks = min((unsigned int)(nelements + threads - 1) / threads, 500);

    imhist_sm_cmap<<<blocks, threads, bufferSize>>>(I, counts, nelements, nbins);
}

#endif // __CUDACC__

#endif // __MW_CUDAIMHIST_UTIL_H__
