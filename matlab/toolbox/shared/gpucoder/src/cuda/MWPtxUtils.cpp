// Copyright 2018-2024 The MathWorks, Inc.

#include "MWPtxUtils.hpp"

#ifdef MATLAB_MEX_FILE
#include "mex.h"
#endif

#include <sstream>

namespace mw_ptx_utils {

void initialize(const char* ptxData,
                const std::vector<const char*>& mangledNames,
                CUmodule& module,
                std::vector<CUfunction>& functionHandles,
                bool reload) {
    if (reload || functionHandles.empty()) {
        loadPtx(ptxData, module);
        loadFunctionsFromModule(module, mangledNames, functionHandles);
    }
}

void loadPtx(const char* ptxData, CUmodule& module) {
    CUresult loadResult = cuModuleLoadFatBinary(&module, ptxData);
    if (loadResult != CUDA_SUCCESS) {
        throwError("Failed to load CUDA module", loadResult);
    }
}

void loadFunctionsFromModule(const CUmodule& module,
                             const std::vector<const char*>& mangledNames,
                             std::vector<CUfunction>& functionHandles) {
    for (std::vector<const char*>::const_iterator it = mangledNames.begin();
         it != mangledNames.end(); ++it) {
        CUfunction handle = loadFunction(module, *it);
        functionHandles.push_back(handle);
    }
}

CUfunction loadFunction(const CUmodule& module, const char* mangledName) {
    CUfunction handle;
    CUresult result = cuModuleGetFunction(&handle, module, mangledName);
    if (result != CUDA_SUCCESS) {
        std::stringstream errorMessageStream;
        errorMessageStream << "Unable to find function " << mangledName
                           << " in the module. Load module failed with following error";
        std::string errorMessage(errorMessageStream.str());
        throwError(errorMessage, result);
    }
    return handle;
}

CUresult launchKernel(CUfunction kernel,
                      dim3 blocks,
                      dim3 threads,
                      void** args,
                      unsigned int sharedMem,
                      CUstream stream,
                      void** extra) {
    return cuLaunchKernel(kernel, blocks.x, blocks.y, blocks.z, threads.x, threads.y, threads.z,
                          sharedMem, stream, args, extra);
}

CUresult launchKernelWithCheck(CUfunction kernel,
                               dim3 blocks,
                               dim3 threads,
                               void** args,
                               unsigned int sharedMem,
                               CUstream stream,
                               void** extra) {
    CUresult result = launchKernel(kernel, blocks, threads, args, sharedMem, stream, extra);
    if (result != CUDA_SUCCESS) {
        throwError("Error while evaluating kernel", result);
    }
    return result;
}

void throwError(const std::string& message) {
#ifdef MATLAB_MEX_FILE
    mexErrMsgIdAndTxt("gpucoder:ptxMexError", message.c_str());
#else
    throw std::runtime_error(message);
#endif
}

void throwError(const std::string& message, const CUresult& error) {
    if (error == CUDA_SUCCESS) {
        return;
    }
    const char* errorString;
    cuGetErrorString(error, &errorString);

    std::string fullMessage = message + " - ";
    fullMessage += errorString;
    throwError(fullMessage);
}

void throwError(const std::string& message, const cudaError_t& error) {
    if (error == cudaSuccess) {
        return;
    }
    const char* errorString = cudaGetErrorString(error);

    std::string fullMessage = message + " - ";
    fullMessage += errorString;
    throwError(fullMessage);
}

} // namespace mw_ptx_utils
