// Copyright 2024 The MathWorks, Inc.
/**
 * @file VDBMeshOperations.cpp
 * @brief This file contains the mesh-specific operations on the VDBManager.
 * @copyright 2024 The MathWorks, Inc.
 */
#ifdef BUILDING_LIBMWVDBVOLUMECODEGEN
#include "vdbvolumecodegen/VDBMeshOperations.hpp"
#else
#include "VDBMeshOperations.hpp"
#endif

namespace nav {
    template <class Data_T, class Size_T>
    MeshDataAdapter<Data_T,Data_T,Size_T> createMesh(float resolution, Data_T const* const pose, const Size_T nVert,
        Data_T const* const vertices, const Size_T nFace, Data_T const* const faces) {
        // Create local cell-centered transformation
        openvdb::math::Transform::Ptr tform = nav::createLocalTransform(resolution, true);

        // Create voxel-centered mesh
        return MeshDataAdapter<Data_T, Data_T, size_t>(tform, nVert, vertices, nFace, faces);
    }

    template <class Mesh>
    DistGridType::Ptr discretizeMesh(const Mesh& mesh, float truncDist, float resolution, bool fillInterior, bool fastSweep) {

        float exteriorDist = truncDist * resolution;
        float interiorDist = fillInterior ? std::numeric_limits<float>::max() : exteriorDist;
        auto tform = mesh.m_tform;
        DistGridType::Ptr meshSDFPtr;

        if (fastSweep) {
            meshSDFPtr =
                openvdb::tools::meshToVolume<DistGridType>(mesh, *tform, exteriorDist, interiorDist, 0);
        }
        else {
            openvdb::Int32Grid polyIdxGrid(0);
            polyIdxGrid.setTransform(tform);
            meshSDFPtr = openvdb::tools::meshToVolume<DistGridType>(mesh, *tform, exteriorDist,
                interiorDist, 0, &polyIdxGrid);

            // Recompute distance for all active voxels using nearest polygon
            size_t i = 0;
            auto idxAccessor = polyIdxGrid.getConstUnsafeAccessor();
            for (auto iter = meshSDFPtr->beginValueOn(); iter.test(); ++iter, i++) {
                // Project point onto the nearest polygon
                openvdb::Vec3d a, b, c, uvw;
                openvdb::Coord pIdx = iter.getCoord();
                size_t polyIdx = idxAccessor.getValue(pIdx);
                mesh.getIndexSpacePoint(polyIdx, 0, a);
                mesh.getIndexSpacePoint(polyIdx, 1, b);
                mesh.getIndexSpacePoint(polyIdx, 2, c);
                openvdb::Vec3d pt =
                    openvdb::math::closestPointOnTriangleToPoint(a, b, c, pIdx.asVec3d(), uvw);

                // Compute distance in world coordinates
                float newDist = static_cast<float>((pt - pIdx.asVec3d()).length());
                newDist *= static_cast<float>(meshSDFPtr->voxelSize().x());

                // Update the distance stored in the voxel
                iter.modifyValue([&](float& dist) { dist = std::signbit(dist) ? -newDist : newDist; });

                // TODO g2982485: Fix case where voxel belongs to multiple polygons. Do this by finding
                // all neighbors which belong to different polygons, compute distance to those polygons
                // and retain the min.
            }
        }
        return meshSDFPtr;
    }

    void transformGrid(DistGridType::Ptr grid, float resolution, const double* const pose) {
        // Create local cell-centered transformation
        openvdb::math::Transform::Ptr tform = nav::createLocalTransform(resolution, true);

        // 4x4 being passed col-major from MATLAB, but openvdb applies 4x4 transforms
        // via post-multiplication. We can therefore read/write OpenVDB matrices without
        // transposing.
        auto poseMat = openvdb::math::Mat4d(pose);
        auto cellCtrMap = tform->baseMap()->getAffineMap()->getMat4();
        tform = openvdb::math::Transform::createLinearTransform(cellCtrMap * poseMat);
        grid->setTransform(tform);
    }

    double addMesh(VDBManager& mgr,
        const size_t id,
        const double* const pose,
        const size_t nVert,
        const double* const vertices,
        const size_t nFace,
        const double* const faces) {

        float res = mgr.getRes();
        float truncDist = mgr.getTruncDist();
        float fillInterior = mgr.getFillInterior();
        auto vdbSet = mgr.getVDBSet();
        bool fastSweep = mgr.getFastSweep();
        
        openvdb::math::Transform::Ptr tform = nav::createLocalTransform(res, true);

        double isNewID = static_cast<double>(!vdbSet.count(id));
        if (isNewID) {
            // Create local cell-centered transformation
            openvdb::math::Transform::Ptr tform = nav::createLocalTransform(res, true);

            // Create mesh adapter with cell-centered voxels
            MeshDataAdapter<double, double, size_t> mesh(tform, nVert, vertices, nFace, faces);

            // Discretize the mesh into a new TSDF grid
            DistGridType::Ptr newTSDF = discretizeMesh(mesh,truncDist,res,fillInterior,fastSweep);

            // Update the pose and add the TSDF to the manager
            transformGrid(newTSDF, res, pose);
            mgr.addElem(id, newTSDF);
        }
        return isNewID;
    }

}
