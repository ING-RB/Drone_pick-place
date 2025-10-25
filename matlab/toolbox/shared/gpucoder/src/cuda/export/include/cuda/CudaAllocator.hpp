/* Copyright 2021-2024 The MathWorks, Inc. */
#ifndef CUDA_ALLOCATOR_HPP
#define CUDA_ALLOCATOR_HPP

#include "Allocator.hpp"

#include <array>

namespace gcmemory {

class CudaAllocator : public Allocator {
  public:
    enum MallocMode { DISCRETE, UNIFIED };

    CudaAllocator(MallocMode mode);
    cudaError_t rawMalloc(void** devPtr, size_t size);
    cudaError_t rawFree(void* devPtr);
    cudaError_t getMemInfo(size_t& freeMemory, size_t& totalMemory);
    size_t calculateBlockSize(size_t size);
    size_t calculatePoolSize(size_t size);

  private:
    static const size_t MEGA_BYTE;
    static const std::array<size_t, 5> SIZE_LEVELS;

    size_t roundUpPoolSizeWithLevel(size_t size);
    size_t roundDownPoolSizeWithGpuFreeMemory(size_t size);

    const MallocMode fMode;
};

} // namespace gcmemory

#endif
