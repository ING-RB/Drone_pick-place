// Copyright 2023-2024 The MathWorks, Inc.
#ifdef BUILDING_LIBMWVDBVOLUMECODEGEN
#include "vdbvolumecodegen/vdbmanager_api.hpp"
#include "vdbvolumecodegen/VDBManager.hpp"
#include "vdbvolumecodegen/VDBMeshOperations.hpp"
#else
#include "vdbmanager_api.hpp"
#include "VDBManager.hpp"
#include "VDBMeshOperations.hpp"
#endif

#include "vdbfusion/VDBVolume.h"
#include <string.h>

static const double ZERO_POSE[16]{ 1,0,0,0,
                                  0,1,0,0,
                                  0,0,1,0,
                                  0,0,0,1 };

vdbfusion::VDBVolume getVDBLayer(void* distPtr, void* weightPtr, size_t id, bool fullTracing = false) {
    // Create VDBVolume wrapper
    auto& distMgr = *static_cast<nav::VDBManager*>(distPtr);
    auto& weightMgr = *static_cast<nav::VDBManager*>(weightPtr);
    float voxSize   = static_cast<float>(1 / distMgr.getRes());
    float truncDist = static_cast<float>(distMgr.getTruncDist());

    // Initialize VDBVolume object
    auto vdbVol = vdbfusion::VDBVolume(voxSize,truncDist,fullTracing);

    if (distMgr.getVDBSet().count(id) != 0) {
        // Retrieve existing grids from vdbmanagers
        vdbVol.tsdf_    = distMgr.getVDBSet()[id];
        vdbVol.weights_ = weightMgr.getVDBSet()[id];
    }
    return vdbVol;
}

EXTERN_C VDBMANAGER_EXPORT_API void tsdfmap_freeDoublePtr(void* opaquePtr) {
    delete[] static_cast<double*>(opaquePtr);
}

EXTERN_C VDBMANAGER_EXPORT_API void tsdfmap_insertPointCloud(void* distPtr, void* weightPtr,
    uint64_T id, bool fullTracing, double const * const origData, double const * const ptData, uint64_T N) {
    
    // Extract inputs
    Eigen::Vector3d origin(origData); // [x,y,z]
    std::vector<Eigen::Vector3d> pts(N);
    for (uint64_T i = 0; i < N; i++) {
        pts[i][0] = ptData[i];
        pts[i][1] = ptData[i + N];
        pts[i][2] = ptData[i + N * 2];
    }

    auto& distMgr = *static_cast<nav::VDBManager*>(distPtr);
    auto& weightMgr = *static_cast<nav::VDBManager*>(weightPtr);

    // Wrap dist/weight layer in VDBVolume
    vdbfusion::VDBVolume vdbWrapper = getVDBLayer(distPtr,weightPtr,static_cast<size_t>(id),fullTracing);

    // TODO: Unshift grids due to VDBFusion not using indexToWorldCellCentered
    nav::applyPoseToGrid(vdbWrapper.tsdf_,distMgr.getRes(),ZERO_POSE,/*voxelCentered*/false);
    nav::applyPoseToGrid(vdbWrapper.weights_,weightMgr.getRes(),ZERO_POSE,/*voxelCentered*/false);

    // Integrate pointcloud
    vdbWrapper.Integrate(pts, origin, nav::vdbfusionMeanWeightFcn);

    // TODO: Apply cell-centered transform. NOTE that this must be fixed prior to
    //       Allowing users to set the pose of signedDistanceMap3D layers.
    nav::applyPoseToGrid(vdbWrapper.tsdf_,distMgr.getRes(),ZERO_POSE,/*voxelCentered*/true);
    nav::applyPoseToGrid(vdbWrapper.weights_,weightMgr.getRes(),ZERO_POSE,/*voxelCentered*/true);

    // Update the managers
    distMgr.addElem(id, vdbWrapper.tsdf_);
    weightMgr.addElem(id, vdbWrapper.weights_);

    // Update the managers
    static_cast<nav::VDBManager*>(distPtr)->recomputeLimits();
    static_cast<nav::VDBManager*>(distPtr)->tallyActiveVoxel();
}

EXTERN_C VDBMANAGER_EXPORT_API void tsdfmap_createMesh(void* distPtr, void* weightPtr,
    uint64_T id, bool fillHoles, float minWeight, double** ptData, uint64_T* nVert, double** faceData, uint64_T* nTri)
{
    // Wrap dist/weight layer in VDBVolume
    vdbfusion::VDBVolume vdbWrapper = getVDBLayer(distPtr,weightPtr,static_cast<size_t>(id));

    // Extract mesh creation parameters
    auto [vertices, triangles] = vdbWrapper.ExtractTriangleMesh(fillHoles, minWeight);

    // Allocate outputs
    size_t nV = vertices.size();
    size_t nT = triangles.size();
    *nVert = static_cast<uint64_T>(nV);
    *nTri = static_cast<uint64_T>(nT);
    *ptData = new double[(*nVert)*3];
    *faceData = new double[(*nTri)*3];
    double *vPtr = *ptData, *fPtr = *faceData;

    for (size_t i = 0; i < nV; i++) {
        Eigen::Vector3d v = vertices[i];
        vPtr[i] = v[0];
        vPtr[i + nV] = v[1];
        vPtr[i + nV * 2] = v[2];
    }

    for (size_t i = 0; i < nT; i++) {
        Eigen::Vector3i f = triangles[i];
        fPtr[i] = static_cast<double>(f[0]) + 1;
        fPtr[i + nT] = static_cast<double>(f[1]) + 1;
        fPtr[i + nT * 2] = static_cast<double>(f[2]) + 1;
    }
}

EXTERN_C VDBMANAGER_EXPORT_API void* vdbmanager_initialize(const double resolution,
                                                           const double truncDist,
                                                           const bool fillInterior,
                                                           const bool fastSweep) {
    // Create manager
    return static_cast<void*>(new nav::VDBManager(resolution, truncDist, fillInterior, fastSweep));
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_cleanup(void* mgr) {
    delete static_cast<nav::VDBManager*>(mgr);
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getNumVDB(void* mgr) {
    return static_cast<double>(static_cast<nav::VDBManager*>(mgr)->getNumVDB());
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getTruncDist(void* mgr) {
    return static_cast<double>(static_cast<nav::VDBManager*>(mgr)->getTruncDist());
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getResolution(void* mgr) {
    return static_cast<double>(static_cast<nav::VDBManager*>(mgr)->getRes());
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getFillInterior(void* mgr) {
    return static_cast<double>(static_cast<nav::VDBManager*>(mgr)->getFillInterior());
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getSignedDistanceMode(void* mgr) {
    return static_cast<double>(static_cast<nav::VDBManager*>(mgr)->getFastSweep());
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_getActiveBoundingBox(void* mgr, double* data) {
    static_cast<nav::VDBManager*>(mgr)->getMapWorldLimits(data);
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_getID(void* mgr, double* idSet) {
    static_cast<nav::VDBManager*>(mgr)->getID(idSet);
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getNumActiveVoxel(void* mgr) {
    return static_cast<double>(static_cast<nav::VDBManager*>(mgr)->getNumActiveVoxel());
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getNumActiveVoxelInVDB(void* mgr, double meshID) {
    return static_cast<double>(
        static_cast<nav::VDBManager*>(mgr)->getNumActiveVoxel(static_cast<size_t>(meshID)));
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_addMesh(void* mgr,
                                                         const double id,
                                                         const double* const pose,
                                                         const double nVert,
                                                         const double* const vertices,
                                                         const double nFace,
                                                         const double* const faces) {
    return nav::addMesh(*static_cast<nav::VDBManager*>(mgr), static_cast<size_t>(id), pose, static_cast<size_t>(nVert), vertices, static_cast<size_t>(nFace), faces);         
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_updatePose(void* mgr,
                                                            const double id,
                                                            const double* const pose) {
    double success = static_cast<nav::VDBManager*>(mgr)->transformGrid(static_cast<size_t>(id), pose);
    if (success) {
        static_cast<nav::VDBManager*>(mgr)->recomputeLimits();
    }
    return success;
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_removeIDs(void* mgr,
                                                          const double* const id,
                                                          const double numID) {
    size_t nId = static_cast<size_t>(numID);
    std::vector<size_t> idVec(nId);
    std::transform(id, id + nId, idVec.begin(), [](double el) { return static_cast<size_t>(el); });
    static_cast<nav::VDBManager*>(mgr)->removeID(idVec);
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_getActiveVoxelFrom(void* mgr, double id, double* ctr, double* dist, double* size) {
    static_cast<nav::VDBManager*>(mgr)->getActiveVoxelFrom(static_cast<size_t>(id), ctr, dist, size);
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_getPoseFrom(void* mgr, double id, double* pose) {
    static_cast<nav::VDBManager*>(mgr)->getPoseFrom(static_cast<size_t>(id), pose);
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_distance(void* mgr,
                                                        const double* const pts,
                                                        const double numPts,
                                                        const double interpMethod,
                                                        double* const distData) {
    // Convert points to openvdb format
    size_t nPt = static_cast<size_t>(numPts);
    std::vector<openvdb::Vec3d> vdbPts(nPt);
    for (size_t i = 0; i < nPt; i++) {
        vdbPts[i] = openvdb::Vec3d(pts[i], pts[i + nPt], pts[i + nPt * 2]);
        distData[i] = std::numeric_limits<double>::max();
    }

    // Compute min distance to the set of discretized meshes
    static_cast<nav::VDBManager*>(mgr)->distance(vdbPts, distData,
                                                 static_cast<const size_t>(interpMethod));
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_gradient(void* mgr,
                                                        const double* const pts,
                                                        const double numPts,
                                                        const double interpMethod,
                                                        double* const gradData) {
    // Convert points to openvdb format
    size_t nPt = static_cast<size_t>(numPts);
    std::vector<openvdb::Vec3d> vdbPts(nPt);
    for (size_t i = 0; i < nPt; i++) {
        vdbPts[i] = openvdb::Vec3d(pts[i], pts[i + nPt], pts[i + nPt * 2]);
    }

    // Compute gradient at query point relative to nearest/deepest mesh
    static_cast<nav::VDBManager*>(mgr)->gradient(vdbPts, gradData,
                                                 static_cast<const size_t>(interpMethod));
}

EXTERN_C VDBMANAGER_EXPORT_API double vdbmanager_getSerializeSize(void* mgr) {
    // Convert map to a string
    std::string mgrData = static_cast<nav::VDBManager*>(mgr)->serialize();
    return static_cast<double>(mgrData.size());
}

EXTERN_C VDBMANAGER_EXPORT_API void vdbmanager_serialize(void* mgr, char* const data) {
    // Convert map to a string
    std::string mgrData = static_cast<nav::VDBManager*>(mgr)->serialize();

    // Copy ostream data to output buffer
    mgrData.copy(data, mgrData.size());
}

EXTERN_C VDBMANAGER_EXPORT_API void* vdbmanager_deserialize(const char* const data,
                                                            const double bufferLength) {
    // Convert the converted char array to string
    std::string mgrString(data, static_cast<size_t>(bufferLength));

    // Deserialize to create a new VDBManager object
    nav::VDBManager* tmp = new nav::VDBManager(nav::VDBManager::deserialize(mgrString));
    return static_cast<void*>(tmp);
}
