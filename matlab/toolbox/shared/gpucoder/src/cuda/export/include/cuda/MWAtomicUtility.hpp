/* Copyright 2017-2024 The MathWorks, Inc. */

#ifndef __MW_ATOMIC_UTILS_H__
#define __MW_ATOMIC_UTILS_H__

#ifdef __CUDACC__

/********** AtomicAdd ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicAdd(T* u1, T u2) {
    return atomicAdd(u1, u2);
}

#if __CUDA_ARCH__ < 600
template <>
__device__ __forceinline__ double gpu_atomicAdd<double>(double* address, double val) {
    unsigned long long int* address_as_ull = (unsigned long long int*)address;
    unsigned long long int old = *address_as_ull;
    unsigned long long int assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        __double_as_longlong(val + __longlong_as_double(assumed)));

        // Note: uses integer comparison to avoid hang in case of NaN (since NaN != NaN)
    } while (assumed != old);

    return __longlong_as_double(old);
}
#endif

static __device__ __forceinline__ unsigned long int gpu_atomicAdd(unsigned long int* u1,
                                                                  unsigned long int u2) {

    return (unsigned long int)atomicAdd((unsigned long long int*)u1, (unsigned long long int)u2);
}

/********** AtomicSub ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicSub(T* u1, T u2) {
    return atomicSub(u1, u2);
}

/********** AtomicExch ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicExch(T* u1, T u2) {
    return atomicExch(u1, u2);
}

static __device__ __forceinline__ unsigned long int gpu_atomicExch(unsigned long int* u1,
                                                                   unsigned long int u2) {

    return (unsigned long int)atomicExch((unsigned long long int*)u1, (unsigned long long int)u2);
}

/********** AtomicMin ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicMin(T* u1, T u2) {
    return atomicMin(u1, u2);
}

static __device__ __forceinline__ unsigned long int gpu_atomicMin(unsigned long int* u1,
                                                                  unsigned long int u2) {

#if __CUDA_ARCH__ >= 350
    return (unsigned long int)atomicMin((unsigned long long int*)u1, (unsigned long long int)u2);
#else
    return 0;
#endif
}

/********** AtomicMax ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicMax(T* u1, T u2) {
    return atomicMax(u1, u2);
}

static __device__ __forceinline__ unsigned long int gpu_atomicMax(unsigned long int* u1,
                                                                  unsigned long int u2) {

#if __CUDA_ARCH__ >= 350
    return (unsigned long int)atomicMax((unsigned long long int*)u1, (unsigned long long int)u2);
#else
    return 0;
#endif
}

/********** AtomicInc ***********/

static __device__ __forceinline__ unsigned int gpu_atomicInc(unsigned int* u1, unsigned int u2) {
    return atomicInc(u1, u2);
}

/********** AtomicDec ***********/

static __device__ __forceinline__ unsigned int gpu_atomicDec(unsigned int* u1, unsigned int u2) {
    return atomicDec(u1, u2);
}

/********** AtomicAnd ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicAnd(T* u1, T u2) {
    return atomicAnd(u1, u2);
}

static __device__ __forceinline__ unsigned long int gpu_atomicAnd(unsigned long int* u1,
                                                                  unsigned long int u2) {

#if __CUDA_ARCH__ >= 350
    return (unsigned long int)atomicAnd((unsigned long long int*)u1, (unsigned long long int)u2);
#else
    return 0;
#endif
}

/********** AtomicOr ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicOr(T* u1, T u2) {
    return atomicOr(u1, u2);
}

static __device__ __forceinline__ unsigned long int gpu_atomicOr(unsigned long int* u1,
                                                                 unsigned long int u2) {

#if __CUDA_ARCH__ >= 350
    return (unsigned long int)atomicOr((unsigned long long int*)u1, (unsigned long long int)u2);
#else
    return 0;
#endif
}

/********** AtomicXor ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicXor(T* u1, T u2) {
    return atomicXor(u1, u2);
}

static __device__ __forceinline__ unsigned long int gpu_atomicXor(unsigned long int* u1,
                                                                  unsigned long int u2) {

#if __CUDA_ARCH__ >= 350
    return (unsigned long int)atomicXor((unsigned long long int*)u1, (unsigned long long int)u2);
#else
    return 0;
#endif
}

/********** AtomicCAS ***********/

template <class T>
static __device__ __forceinline__ T gpu_atomicCAS(T* u1, T u2, T u3) {
    return atomicCAS(u1, u2, u3);
}

static __device__ __forceinline__ unsigned long int gpu_atomicCAS(unsigned long int* u1,
                                                                  unsigned long int u2,
                                                                  unsigned long int u3) {

    return (unsigned long int)atomicCAS((unsigned long long int*)u1, (unsigned long long int)u2,
                                        (unsigned long long int)u3);
}

#endif
#endif
