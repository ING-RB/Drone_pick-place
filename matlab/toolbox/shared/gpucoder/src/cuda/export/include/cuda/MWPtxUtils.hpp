/* Copyright 2018-2024 The MathWorks, Inc. */

#ifndef PTX_WRAPPER_UTILS_HPP
#define PTX_WRAPPER_UTILS_HPP

#include <cuda.h>
#include <cuda_runtime.h>

#include <vector>
#include <string>

namespace mw_ptx_utils {

/**
 * Initializes a function for use with PTX kernels.
 * First, the PTX data is loaded into the given module.
 * The function handles are then extracted into the functionHandles
 * vector using the mangled function names. If reload is true,
 * the PTX will always be reloaded. Otherwise, no action will
 * occur if functionHandles is not empty.
 */
void initialize(const char* ptxData,
                const std::vector<const char*>& mangledNames,
                CUmodule& module,
                std::vector<CUfunction>& functionHandles,
                bool reload = false);

/**
 * Loads the given PTX data into the given CUDA module.
 */
void loadPtx(const char* ptxData, CUmodule& module);

/**
 * Loads functions from the given module into the functionHandles
 * vector using an array of mangled names.
 */
void loadFunctionsFromModule(const CUmodule& module,
                             const std::vector<const char*>& mangledNames,
                             std::vector<CUfunction>& functionHandles);

/**
 * Loads an individual function from a module using its mangled name.
 */
CUfunction loadFunction(const CUmodule& module, const char* functionName);

/**
 * Launches a kernel using the CUDA driver API and returns
 * the result.
 */
CUresult launchKernel(CUfunction kernel,
                      dim3 blocks,
                      dim3 threads,
                      void** args,
                      unsigned int sharedMem = 0,
                      CUstream stream = NULL,
                      void** extra = NULL);

/**
 * Launches a kernel and throws an error if the result
 * is not CUDA_SUCCESS.
 */
CUresult launchKernelWithCheck(CUfunction kernel,
                               dim3 blocks,
                               dim3 threads,
                               void** args,
                               unsigned int sharedMem = 0,
                               CUstream stream = NULL,
                               void** extra = NULL);

/**
 * If this code is being executed inside a MEX, this function
 * throws a MEX error into MATLAB with the given message.
 * Otherwise, a std::runtime_exception is thrown with the
 * given message.
 */
void throwError(const std::string& message);

/**
 * Formats the CUDA error into the given string and forwards to
 * throwError(const std::string& message).
 */
void throwError(const std::string& message, const CUresult& error);

/**
 * Formats the CUDA error into the given string and forwards to
 * throwError(const std::string& message).
 */
void throwError(const std::string& message, const cudaError_t& error);

} // namespace mw_ptx_utils

#endif // PTX_WRAPPER_UTILS_HPP
