/**
 * @file DPGrid codegen C interface
 * @brief This file contains the definitions for C-API interfaces
 */

/* Copyright 2024 The MathWorks, Inc. */

#ifdef BUILDING_LIBMWDPGRIDCODEGEN
#include "dpgridcodegen/dpgrid.hpp"
#include "dpgridcodegen/dpgrid_api.hpp"
#else
/* To deal with the fact that PackNGo has no include file hierarchy during test */
#include "dpgrid.hpp"
#include "dpgrid_api.hpp"
#endif

EXTERN_C DPGRID_CODEGEN_API void* dpgrid_construct(const boolean_T* mapMatrix,
                                                   const uint32_T rows,
                                                   const uint32_T cols) {
    // Construct DPGrid object
    std::vector<std::vector<bool>> mapMatrixVec(rows, std::vector<bool>(cols));
    uint32_t count = 0;

    // Convert the mapMatrix into a 2D vector
    // mapMatrix is an 1D array that stores the matrix in column-major format
    // For e.g., if the original matrix is [1,1,1,1;0,0,0,0] then
    // mapMatrix is {1,0,1,0,1,0,1,0}
    for (uint32_t i = 0; i < cols; ++i) {
        for (uint32_t j = 0; j < rows; ++j) {
            mapMatrixVec[j][i] = mapMatrix[count];
            count++;
        }
    }
    return static_cast<void*>(new nav::DPGrid(mapMatrixVec));
}

EXTERN_C DPGRID_CODEGEN_API void dpgrid_destruct(void* dpObj) {
    // Destruct DPGrid object
    delete static_cast<nav::DPGrid*>(dpObj);
}

EXTERN_C DPGRID_CODEGEN_API void dpgrid_setGoal(void* dpObj, const uint32_T* goal) {
    // Set goal for DPGrid search
    static_cast<nav::DPGrid*>(dpObj)->setGoal(goal);
}

EXTERN_C DPGRID_CODEGEN_API real64_T dpgrid_getPathCost(void* dpObj, const uint32_T* start) {
    // Get path cost from DPGrid search for a given start cell
    return static_cast<nav::DPGrid*>(dpObj)->getPathCost(start);
}
