// Copyright 2024 The MathWorks, Inc.
#pragma once

#include <cstdint>
#include <cuda_runtime.h>

/// This file contains inline device functions that wrap PTX instructions related to tensor cores,
/// including MMA and LDSM (load matrix from shared memory) instructions.
/// These handwritten device functions are called by the generated kernel, and this file is expected
/// to be copied to the codegen directory. Note that this file contains functions requiring
/// different compute capabilities; however, only the functions used by the kernel will eventually
/// be compiled by the NVCC compiler.

#if defined(__NVCC__)

#define MW_DEVICE_INLINE __device__ __inline__

static MW_DEVICE_INLINE uint32_t cast_smem_ptr_to_uint(void const* ptr) {
    return static_cast<uint32_t>(__cvta_generic_to_shared(ptr));
}

static MW_DEVICE_INLINE void MW_SM75_U32x1_LDSM_N(void const* smem_src, uint32_t* dst) {
    uint32_t smem_int_ptr = cast_smem_ptr_to_uint(smem_src);
    asm volatile("ldmatrix.sync.aligned.x1.m8n8.shared.b16 {%0}, [%1];\n"
                 : "=r"(*dst)
                 : "r"(smem_int_ptr));
}

static MW_DEVICE_INLINE void MW_SM75_U32x2_LDSM_N(void const* smem_src,
                                                  uint32_t* dst0,
                                                  uint32_t* dst1) {
    uint32_t smem_int_ptr = cast_smem_ptr_to_uint(smem_src);
    asm volatile("ldmatrix.sync.aligned.x2.m8n8.shared.b16 {%0, %1}, [%2];\n"
                 : "=r"(*dst0), "=r"(*dst1)
                 : "r"(smem_int_ptr));
}

static MW_DEVICE_INLINE void MW_SM75_U32x4_LDSM_N(void const* smem_src,
                                                  uint32_t* dst0,
                                                  uint32_t* dst1,
                                                  uint32_t* dst2,
                                                  uint32_t* dst3) {
    uint32_t smem_int_ptr = cast_smem_ptr_to_uint(smem_src);
    asm volatile("ldmatrix.sync.aligned.x4.m8n8.shared.b16 {%0, %1, %2, %3}, [%4];\n"
                 : "=r"(*dst0), "=r"(*dst1), "=r"(*dst2), "=r"(*dst3)
                 : "r"(smem_int_ptr));
}

static MW_DEVICE_INLINE void MW_SM75_16x8x8_F16F16F16F16_TN(uint32_t* d0,
                                                            uint32_t* d1,
                                                            uint32_t a0,
                                                            uint32_t a1,
                                                            uint32_t b0,
                                                            uint32_t c0,
                                                            uint32_t c1) {
    asm volatile(
        "mma.sync.aligned.m16n8k8.row.col.f16.f16.f16.f16 "
        "{%0, %1},"
        "{%2, %3},"
        "{%4},"
        "{%5, %6};\n"
        : "=r"(*d0), "=r"(*d1)
        : "r"(a0), "r"(a1), "r"(b0), "r"(c0), "r"(c1));
}

static MW_DEVICE_INLINE void MW_SM75_16x8x8_F32F16F16F32_TN(float* d0,
                                                            float* d1,
                                                            float* d2,
                                                            float* d3,
                                                            uint32_t a0,
                                                            uint32_t a1,
                                                            uint32_t b0,
                                                            float c0,
                                                            float c1,
                                                            float c2,
                                                            float c3) {
    asm volatile(
        "mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32 "
        "{%0, %1, %2, %3},"
        "{%4, %5},"
        "{%6},"
        "{%7, %8, %9, %10};\n"
        : "=f"(*d0), "=f"(*d1), "=f"(*d2), "=f"(*d3)
        : "r"(a0), "r"(a1), "r"(b0), "f"(c0), "f"(c1), "f"(c2), "f"(c3));
}

static MW_DEVICE_INLINE void MW_SM80_16x8x16_F16F16F16F16_TN(uint32_t* d0,
                                                             uint32_t* d1,
                                                             uint32_t a0,
                                                             uint32_t a1,
                                                             uint32_t a2,
                                                             uint32_t a3,
                                                             uint32_t b0,
                                                             uint32_t b1,
                                                             uint32_t c0,
                                                             uint32_t c1) {
    asm volatile(
        "mma.sync.aligned.m16n8k16.row.col.f16.f16.f16.f16 "
        "{%0, %1},"
        "{%2, %3, %4, %5},"
        "{%6, %7},"
        "{%8, %9};\n"
        : "=r"(*d0), "=r"(*d1)
        : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(c0), "r"(c1));
}

static MW_DEVICE_INLINE void MW_SM80_16x8x16_F32F16F16F32_TN(float* d0,
                                                             float* d1,
                                                             float* d2,
                                                             float* d3,
                                                             uint32_t a0,
                                                             uint32_t a1,
                                                             uint32_t a2,
                                                             uint32_t a3,
                                                             uint32_t b0,
                                                             uint32_t b1,
                                                             float c0,
                                                             float c1,
                                                             float c2,
                                                             float c3) {
    asm volatile(
        "mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 "
        "{%0, %1, %2, %3},"
        "{%4, %5, %6, %7},"
        "{%8, %9},"
        "{%10, %11, %12, %13};\n"
        : "=f"(*d0), "=f"(*d1), "=f"(*d2), "=f"(*d3)
        : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "f"(c0), "f"(c1), "f"(c2), "f"(c3));
    ;
}

static MW_DEVICE_INLINE void MW_SM80_16x8x8_F32BF16BF16F32_TN(float* d0,
                                                              float* d1,
                                                              float* d2,
                                                              float* d3,
                                                              uint32_t a0,
                                                              uint32_t a1,
                                                              uint32_t b0,
                                                              float c0,
                                                              float c1,
                                                              float c2,
                                                              float c3) {
    asm volatile(
        "mma.sync.aligned.m16n8k8.row.col.f32.bf16.bf16.f32 "
        "{%0, %1, %2, %3},"
        "{%4, %5},"
        "{%6},"
        "{%7, %8, %9, %10};\n"
        : "=f"(*d0), "=f"(*d1), "=f"(*d2), "=f"(*d3)
        : "r"(a0), "r"(a1), "r"(b0), "f"(c0), "f"(c1), "f"(c2), "f"(c3));
}

static MW_DEVICE_INLINE void MW_SM80_16x8x16_F32BF16BF16F32_TN(float* d0,
                                                               float* d1,
                                                               float* d2,
                                                               float* d3,
                                                               uint32_t a0,
                                                               uint32_t a1,
                                                               uint32_t a2,
                                                               uint32_t a3,
                                                               uint32_t b0,
                                                               uint32_t b1,
                                                               float c0,
                                                               float c1,
                                                               float c2,
                                                               float c3) {
    asm volatile(
        "mma.sync.aligned.m16n8k16.row.col.f32.bf16.bf16.f32 "
        "{%0, %1, %2, %3},"
        "{%4, %5, %6, %7},"
        "{%8, %9},"
        "{%10, %11, %12, %13};\n"
        : "=f"(*d0), "=f"(*d1), "=f"(*d2), "=f"(*d3)
        : "r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "f"(c0), "f"(c1), "f"(c2), "f"(c3));
    ;
}

#endif // __NVCC__
