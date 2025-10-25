// Copyright 2020-2023 The MathWorks, Inc.

#ifndef MW_ERROR_CODE_UTILS_HPP
#define MW_ERROR_CODE_UTILS_HPP

const char* mwCublasGetErrorName(int errCode);

const char* mwCublasGetErrorString(int errCode);

const char* mwCusolverGetErrorName(int errCode);

const char* mwCusolverGetErrorString(int errCode);

const char* mwCufftGetErrorName(int errCode);

const char* mwCufftGetErrorString(int errCode);

#endif // #ifndef MW_ERROR_CODE_UTILS_HPP
