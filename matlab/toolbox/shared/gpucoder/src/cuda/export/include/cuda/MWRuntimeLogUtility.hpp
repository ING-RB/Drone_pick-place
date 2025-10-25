/* Copyright 2019-2022 The MathWorks, Inc. */
#ifndef MWRUNTIMELOGUTILITY_HPP
#define MWRUNTIMELOGUTILITY_HPP

#ifdef __cplusplus
extern "C" /* sbcheck:ok:extern-c needed because this file is shared by Cuda/OpenCL */ {
#endif

void mwGpuCoderRuntimeLog(const char* msg);

#ifdef __cplusplus
}
#endif

#endif
