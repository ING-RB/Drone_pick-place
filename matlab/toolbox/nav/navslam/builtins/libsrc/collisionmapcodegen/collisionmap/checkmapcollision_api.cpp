/* Copyright 2022-2023 The MathWorks, Inc. */

#ifdef BUILDING_LIBMWCOLLISIONMAPCODEGEN
#include "collisionmapcodegen/checkmapcollision_api.hpp"
#include "collisionmapcodegen/checkMapCollision.hpp"
#include "dynmatcodegen/DynamicMatrixVoidWrapper.hpp"
#include "dynmatcodegen/DynamicMatrix.hpp"
#else
/* To deal with the fact that PackNGo has no include file hierarchy during test */
#include "checkmapcollision_api.hpp"
#include "checkMapCollision.hpp"
#include "DynamicMatrixVoidWrapper.hpp"
#include "DynamicMatrix.hpp"
#endif

#include <array>

EXTERN_C COLLISIONMAP_CODEGEN_API boolean_T
checkmapcollisioncodegen_checkCollision(void* map,
                                        void* geom,
                                        const real64_T* pos1d,
                                        const real64_T* quat1d,
                                        real64_T* distance,
                                        const boolean_T exhaustive,
                                        const boolean_T narrowPhase,
                                        const boolean_T broadPhase,
                                        const uint32_T maxQueryDepth,
                                        real64_T p1Vec[3],
                                        real64_T p2Vec[3],
                                        void** centerPtr,
                                        void** sizePtr,
                                        real64_T center[3],
                                        real64_T pMin[3],
                                        real64_T pMax[3]) {
    // Update the geometry
    shared_robotics::updatePose(geom, static_cast<const ccd_real_t *>(pos1d),
        static_cast<const ccd_real_t *>(quat1d));

    // Initialize voxel-output vectors
    std::vector<std::array<double, 3>>* ctrs = new std::vector<std::array<double, 3>>();
    std::vector<double>* sizes = new std::vector<double>();

    boolean_T isColliding = nav::octomapCheckCollision_impl(
        map, geom, *distance, exhaustive, narrowPhase, broadPhase, maxQueryDepth,
        static_cast<double*>(p1Vec), static_cast<double*>(p2Vec), *ctrs, *sizes,
        static_cast<double*>(center), static_cast<double*>(pMin), static_cast<double*>(pMax));

    // Return dynamic matrices (createWrapper handles conversion from double->real64_T)
    auto* voxelCenters = new nav::DynamicMatrix<std::vector<std::array<double, 3>>, 2>(
        nav::raw2unique(ctrs), {ctrs->size(), 3});
    auto* voxelSizes =
        new nav::DynamicMatrix<std::vector<double>, 1>(nav::raw2unique(sizes), {sizes->size()});
    nav::createWrapper<real64_T>(voxelCenters, *centerPtr);
    nav::createWrapper<real64_T>(voxelSizes, *sizePtr);

    return isColliding;
}
