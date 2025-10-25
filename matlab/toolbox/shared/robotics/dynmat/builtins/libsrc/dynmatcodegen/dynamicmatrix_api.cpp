/* Copyright 2022-2023 The MathWorks, Inc. */

/**
 * @file
 * External C-API interfaces for dynamically allocated DynamicMatrix object.
 * To fully support code generation, note that this file needs to be fully
 * compliant with the C89/C90 (ANSI) standard.
 */

#ifdef BUILDING_LIBMWDYNAMICMATRIXCODEGEN
#include "dynmatcodegen/DynamicMatrixVoidWrapper.hpp"
#else
/* To deal with the fact that PackNGo has no include file hierarchy during test */
#include "DynamicMatrixVoidWrapper.hpp"
#endif

/**
 * @brief Retrieve number of elements in array stored by DynamicMatrixVoidWrapperBase pointer
 *
 * @param voidWrapper void*-cast ptr to DynamicMatrixVoidWrapperBase*
 * @return numel Total number of elements in stored matrix
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API uint64_T dynamicmatrixcodegen_getNumel(void* voidWrapper) {
    auto* objPtr = reinterpret_cast<nav::DynamicMatrixVoidWrapperBase*>(voidWrapper);
    return objPtr->numel();
}

/**
 * @brief Retrieve number of dimensions in array stored by DynamicMatrixVoidWrapperBase pointer
 *
 * @param voidWrapper void*-cast ptr to DynamicMatrixVoidWrapperBase*
 * @return numDim Dimensions of stored matrix in MATLAB
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API uint64_T dynamicmatrixcodegen_getNumDimensions(void* voidWrapper) {
    auto* objPtr = reinterpret_cast<nav::DynamicMatrixVoidWrapperBase*>(voidWrapper);
    return objPtr->numDim();
}

/**
 * @brief Retrieve size of array stored by DynamicMatrixVoidWrapperBase pointer
 *
 * @param voidWrapper void*-cast ptr to DynamicMatrixVoidWrapperBase*
 * @param[out] sz A 1xN array storing the size of the data matrix stored by the DynamicArray
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_getMATLABSize(void* voidWrapper,
                                                                    uint64_T* sz) {
    auto* objPtr = reinterpret_cast<nav::DynamicMatrixVoidWrapperBase*>(voidWrapper);
    objPtr->size(sz);
}


/**
 * @brief Delete pointer to DynamicMatrixVoidWrapperBase
 *
 * @param voidWrapper void*-cast ptr to DynamicMatrixVoidWrapperBase*
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_destruct(void* voidWrapper) {
    auto* objPtr = static_cast<nav::DynamicMatrixVoidWrapperBase*>(voidWrapper);
    if (objPtr != nullptr) {
        delete objPtr; // sbcheck:ok:allocterms
        objPtr = nullptr;
    }
}

/**
 * The following API will copy the data out of the nested container
 * and cast it to the type defined by the function.
 *
 *      NOTE: The API used MUST MATCH the type used to construct the
 *            DynamicMatrixVoidWrapper<type>* (passed here as void*)
 */

template <typename Tout>
void getDataOfType(void* voidWrapper, Tout* out) {
    // Reinterpret the pointer as the base class
    auto* basePtr = reinterpret_cast<nav::DynamicMatrixVoidWrapperBase*>(voidWrapper);

    // Convert to original derived class
    auto* typedPtr = static_cast<nav::DynamicMatrixVoidWrapper<Tout>*>(basePtr);

    // Retrieve data
    typedPtr->data(out);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<real64_T>*
 *
 * @param voidWrapper void*-cast ptr to DynamicMatrixVoidWrapper<real64_T>*
 * @param[out] dest Allocated array of DOUBLES which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_REAL64(void* voidWrapper,
                                                                      real64_T* dest) {
    getDataOfType(voidWrapper, dest);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<real32_T>*
 *
 * @param voidWrapper void*-casted ptr to DynamicMatrixVoidWrapper<real32_T>*
 * @param[out] dest Allocated array of SINGLES which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_REAL32(void* voidWrapper,
                                                                      real32_T* dest) {
    getDataOfType(voidWrapper, dest);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<uint64_T>*
 *
 * @param voidWrapper void*-casted ptr to DynamicMatrixVoidWrapper<uint64_T>*
 * @param[out] dest Allocated array of UINT64 which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_UINT64(void* voidWrapper,
                                                                      uint64_T* dest) {
    getDataOfType(voidWrapper, dest);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<uint32_T>*
 *
 * @param voidWrapper void*-casted ptr to DynamicMatrixVoidWrapper<uint32_T>*
 * @param[out] dest Allocated array of UINT32 which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_UINT32(void* voidWrapper,
                                                                      uint32_T* dest) {
    getDataOfType(voidWrapper, dest);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<int64_T>*
 *
 * @param voidWrapper void*-casted ptr to DynamicMatrixVoidWrapper<int64_T>*
 * @param[out] dest Allocated array of INT64 which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_INT64(void* voidWrapper,
                                                                     int64_T* dest) {
    getDataOfType(voidWrapper, dest);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<int32>*
 *
 * @param voidWrapper void*-casted ptr to DynamicMatrixVoidWrapper<int32_T>*
 * @param[out] dest Allocated array of INT32 which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_INT32(void* voidWrapper,
                                                                     int32_T* dest) {
    getDataOfType(voidWrapper, dest);
}

/**
 * @brief Retrieve data stored by DynamicMatrixVoidWrapper<bool>*
 *
 * @param voidWrapper void*-casted ptr to DynamicMatrixVoidWrapper<boolean_T>*
 * @param[out] dest Allocated array of BOOLEANS which will receive the values stored in voidWrapper
 */
EXTERN_C DYNAMICMATRIX_CODEGEN_API void dynamicmatrixcodegen_retrieve_BOOLEAN(void* voidWrapper,
                                                                       boolean_T* dest) {
    getDataOfType(voidWrapper, dest);
}
