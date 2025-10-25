// Copyright 2023-2024 The MathWorks, Inc.
/**
 * @file VDBManager.cpp
 * @brief This file contains the implementation of the VDBManager object.
 * @copyright 2024 The MathWorks, Inc.
 */

#ifdef BUILDING_LIBMWVDBVOLUMECODEGEN
#include "vdbvolumecodegen/VDBManager.hpp"
#else
#include "VDBManager.hpp"
#endif

namespace nav {

template <class Mesh>
DistGridType::Ptr VDBManager::discretizeMesh(const Mesh& mesh) const {

    float exteriorDist = m_truncDist * m_resolution;
    float interiorDist = m_fillInterior ? std::numeric_limits<float>::max() : exteriorDist;
    auto tform = mesh.m_tform;
    DistGridType::Ptr meshSDFPtr;

    if (m_fastSweep) {
        meshSDFPtr =
            openvdb::tools::meshToVolume<DistGridType>(mesh, *tform, exteriorDist, interiorDist, 0);
    } else {
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
};

double VDBManager::addElem(const size_t id, DistGridType::Ptr newGrid) {
    // Update the pose and add the TSDF to the manager
    m_vdbSet[id] = newGrid;
    m_numActiveVoxel += newGrid->activeVoxelCount();
    openvdb::BBoxd curBBox =
        newGrid->transform().indexToWorld(newGrid->evalActiveVoxelBoundingBox());

    // Expand limits if bbox has been initialized, otherwise set bbox to current
    if (m_mapWorldLimits.hasVolume()) {
        m_mapWorldLimits.expand(curBBox);
    }
    else {
        m_mapWorldLimits = curBBox;
    };
    double isNewID = static_cast<double>(!m_vdbSet.count(id));
    return isNewID;
}

void VDBManager::removeID(const std::vector<size_t>& idSet) {
    size_t prevNum = m_vdbSet.size();

    for (size_t id : idSet) {
        auto el = m_vdbSet.find(id);
        if (el != m_vdbSet.end()) {
            // Remove TSDF
            size_t numVox = el->second->activeVoxelCount();
            m_vdbSet.erase(id);
            m_numActiveVoxel -= numVox;
        }
    }

    if (m_vdbSet.size() != prevNum) {
        recomputeLimits();
    }
}

double VDBManager::transformGrid(const size_t id, const double* const pose) {
    double idFound = static_cast<double>(m_vdbSet.count(id));

    if (idFound) {
        // Create apply cell-centered transformation
        nav::applyPoseToGrid(m_vdbSet[id],m_resolution,pose,/*voxelCentered*/true);
    }
    return idFound;
}

void VDBManager::recomputeLimits(void) {
    if (m_vdbSet.size() == 0u) {
        m_mapWorldLimits = openvdb::BBoxd(nav::DEFAULT_LIMITS.data());
    } else {
        auto it = m_vdbSet.cbegin();
        m_mapWorldLimits =
            it->second->transform().indexToWorld(it->second->evalActiveVoxelBoundingBox());
        while (it != m_vdbSet.end()) {
            m_mapWorldLimits.expand(
                it->second->transform().indexToWorld(it->second->evalActiveVoxelBoundingBox()));
            it++;
        }
    }
}

void VDBManager::tallyActiveVoxel(void) {
    m_numActiveVoxel = 0u;
    std::for_each(m_vdbSet.cbegin(), m_vdbSet.cend(), [&](auto& el) {
        m_numActiveVoxel += static_cast<size_t>(el.second->activeVoxelCount());
    });
}

void computeMinDist(const DistGridType& grid,
                    const std::vector<openvdb::Vec3d>& pts,
                    double* dists,
                    const size_t interpMethod) {
    // Create distance operator
    auto accessor = grid.getConstAccessor();
    std::function<double(const openvdb::Vec3d& pt)> distOp;
    switch (interpMethod) {
    case 0: { // nearesolutiont
        distOp = [&](auto pt) {
            return accessor.getValue(grid.transform().worldToIndexCellCentered(pt));
        };
    }; break;
    case 1: { // linear
        openvdb::tools::GridSampler<DistGridType::ConstAccessor, openvdb::tools::BoxSampler>
            fastSampler(accessor, grid.transform());
        distOp = [&](auto pt) { return fastSampler.wsSample(pt); };
    }; break;
    case 2: { // quadratic
        openvdb::tools::GridSampler<DistGridType::ConstAccessor, openvdb::tools::QuadraticSampler>
            fastSampler(accessor, grid.transform());
        distOp = [&](auto pt) { return fastSampler.wsSample(pt); };
    }; break;
    }

    // Compute min distance
    for (size_t i = 0; i < pts.size(); i++) {
        dists[i] = std::min<double>(dists[i], distOp(pts[i]));
    }
}

void computeMinDist(const DistGridType& grid,
                    const std::vector<openvdb::Vec3d>& pts,
                    double* dists,
                    const size_t interpMethod,
                    std::vector<size_t>& minID,
                    const size_t id) {
    // Create distance operator
    auto accessor = grid.getConstAccessor();
    std::function<float(const openvdb::Vec3d&)> distOp;
    switch (interpMethod) {
    case 0: { // nearest
        distOp = [&grid, &accessor](auto pt) {
            return accessor.getValue(grid.transform().worldToIndexCellCentered(pt));
        };
    }; break;
    case 1: { // linear
        openvdb::tools::GridSampler<DistGridType::ConstAccessor, openvdb::tools::BoxSampler>
            fastSampler(accessor, grid.transform());
        distOp = [&fastSampler](auto pt) { return fastSampler.wsSample(pt); };
    }; break;
    case 2: { // quadratic
        openvdb::tools::GridSampler<DistGridType::ConstAccessor, openvdb::tools::QuadraticSampler>
            fastSampler(accessor, grid.transform());
        distOp = [&fastSampler](auto pt) { return fastSampler.wsSample(pt); };
    }; break;
    }

    // Compute distance operator
    for (size_t i = 0; i < pts.size(); i++) {
        double d = static_cast<double>(distOp(pts[i]));
        if (d < dists[i]) {
            dists[i] = d;
            minID[i] = id;
        }
    }
}

void computeMinGradient(const DistGridType& grid,
                        const std::vector<openvdb::Vec3d>& pts,
                        double* grads,
                        const size_t interpMethod,
                        std::vector<size_t> minID,
                        const size_t id) {
    size_t N = pts.size();
    openvdb::Vec3d gVec;
    switch (interpMethod) {
    case 0: {
        auto stencil = openvdb::math::BoxStencil<DistGridType>(grid);
        for (size_t i = 0; i < N; i++) {
            // Only compute gradient if the current grid was closest to the query point
            if (minID[i] == id) {
                // Move gradient to index-space coordinate and query gradient
                auto ijk = grid.transform().worldToIndexCellCentered(pts[i]);
                stencil.moveTo(ijk);
                gVec = stencil.gradient(ijk.asVec3d());

                grads[i] = gVec.x();
                grads[i + N] = gVec.y();
                grads[i + N * 2] = gVec.z();
            }
        }
    } break;
    case 1: {
        auto stencil = openvdb::math::BoxStencil<DistGridType>(grid);
        for (size_t i = 0; i < N; i++) {
            // Only compute gradient if the current grid was closest to the query point
            if (minID[i] == id) {
                // Move gradient to index-space coordinate and query gradient
                auto ijk = grid.transform().worldToIndex(pts[i]);
                stencil.moveTo(ijk);
                gVec = stencil.gradient(ijk);
                grads[i] = gVec.x();
                grads[i + N] = gVec.y();
                grads[i + N * 2] = gVec.z();
            }
        }
    } break;
    case 2: {
        auto stencil = openvdb::math::GradStencil<DistGridType>(grid);
        for (size_t i = 0; i < N; i++) {
            if (minID[i] == id) {
                // Move gradient to index-space coordinate and query gradient
                auto ijk = grid.transform().worldToIndex(pts[i]);
                stencil.moveTo(ijk);
                gVec = stencil.gradient(ijk);
                grads[i] = gVec.x();
                grads[i + N] = gVec.y();
                grads[i + N * 2] = gVec.z();
            }
        }
    } break;
    }
}

void VDBManager::distance(const std::vector<openvdb::Vec3d>& pts,
                          double* dists,
                          const size_t interpMethod) const {
    for (auto& it : m_vdbSet) {
        computeMinDist(*(it.second), pts, dists, interpMethod);
    }
}

void VDBManager::gradient(const std::vector<openvdb::Vec3d>& pts,
                          double* grads,
                          const size_t interpMethod) const {
    std::vector<size_t> minID(pts.size());

    // First "column" of gradients will be used to track min distance across VDBs, so initialize it
    // to inf
    std::for_each_n(grads, pts.size(), [](auto& el) { el = std::numeric_limits<double>::max(); });

    // Find nearest/deepest mesh for each query point
    for (auto& it : m_vdbSet) {
        // Reuse first "col" of 'grads' as the 'dist' input. This is only needed to determine which
        // VDB contains the nearest geometry to each query point
        computeMinDist(*(it.second), pts, grads, interpMethod, minID, it.first);
    }

    // Find subset of meshes which were closest to at least one query point
    std::unordered_set<size_t> uniqueID;
    std::for_each(minID.cbegin(), minID.cend(), [&](auto el) { uniqueID.insert(el); });

    // Compute gradient for each point using closest/deepest corresponding mesh
    for (auto id : uniqueID) {
        computeMinGradient(*m_vdbSet.at(id), pts, grads, interpMethod, minID, id);
    }
}

void VDBManager::getActiveVoxelFrom(size_t id, double* ctrs, double* vals, double* sizes) const {
    openvdb::CoordBBox idxBBox;
    openvdb::Vec3d ctr;
    auto el = m_vdbSet.find(id);
    if (el != m_vdbSet.end()) {
        auto grid = el->second;
        size_t N = grid->activeVoxelCount();
        size_t ip = 0;

        for (auto it = grid->cbeginValueOn(); it.test(); ++it, ip++) {
            // Get value at voxel center
            vals[ip] = it.getValue();

            // Get voxel size
            it.getBoundingBox(idxBBox);
            sizes[ip] =
                static_cast<double>(idxBBox.extents()[idxBBox.maxExtent()] / m_resolution);

            // Get voxel location
            ctr = grid->transform().indexToWorld(it.getCoord());
            ctrs[ip] = ctr.x();
            ctrs[ip + N] = ctr.y();
            ctrs[ip + N * 2] = ctr.z();
        }
    }
}

void VDBManager::getPoseFrom(size_t id, double* poses) const {
    auto el = m_vdbSet.find(id);
    if (el != m_vdbSet.end()) {
        auto grid = el->second;
        auto tform4x4 = grid->transform().baseMap()->getAffineMap()->getConstMat4();
        auto idxToWorld_local = createLocalTransform(m_resolution, true);
        auto invLocal4x4 =
            idxToWorld_local->baseMap()->inverseMap()->getAffineMap()->getConstMat4();
        tform4x4 = invLocal4x4 * tform4x4; // Remove effect of local point->index conversion,
                                           // leaving only the local->world transformation
        std::copy_n(tform4x4[0], 16, poses);
    }
}

void VDBManager::getID(double* idSet) const {
    size_t i = 0;
    for (auto& el : m_vdbSet) {
        idSet[i] = static_cast<double>(el.first);
        i++;
    }
}

std::string VDBManager::serialize(void) {
    // Make sure default types are initialized
    openvdb::initialize();

    // Create string stream
    std::ostringstream ostr(std::ios_base::binary);

    // Populate MetaMap with manager's metadata
    openvdb::MetaMap map;
    map.insertMeta("m_resolution", openvdb::FloatMetadata(m_resolution));
    map.insertMeta("m_truncDist", openvdb::FloatMetadata(m_truncDist));
    map.insertMeta("m_fillInterior", openvdb::BoolMetadata(m_fillInterior));
    map.insertMeta("m_fastSweep", openvdb::BoolMetadata(m_fastSweep));

    // Populate random-access elements to sequentially-iterated datastructure
    openvdb::GridPtrVecPtr grids(new openvdb::GridPtrVec);
    for (auto& el : m_vdbSet) {
        // Add ID to each grid's metadata
        grids->push_back(el.second);
        grids->back()->insertMeta("ID", openvdb::FloatMetadata(static_cast<float>(el.first)));
    }

    // Write meta-data and grids to a string and return
    openvdb::io::Stream(ostr).write(*grids, map);

    return ostr.str();
}

VDBManager VDBManager::deserialize(std::string& vdbManagerString) {
    // Make sure default types are initialized
    openvdb::initialize();

    // Read meta-data and grids out from the string
    std::istringstream istrm(vdbManagerString, std::ios_base::binary);
    openvdb::io::Stream vdbStream(istrm);
    openvdb::MetaMap::Ptr map = vdbStream.getMetadata();
    openvdb::GridPtrVecPtr grids = vdbStream.getGrids();

    float resolution = map->metaValue<float>("m_resolution");
    float truncDist = map->metaValue<float>("m_truncDist");
    bool fillInterior = map->metaValue<bool>("m_fillInterior");
    bool fastSweep = map->metaValue<bool>("m_fastSweep");

    // Create VDBManager object using the grid's metadata
    VDBManager newObj(static_cast<double>(resolution), static_cast<double>(truncDist), fillInterior,
                      fastSweep);

    // Add all grids to the vdb set
    std::for_each((*grids).begin(), (*grids).end(), [&](openvdb::GridBase::Ptr gridPtr) {
        size_t metaID = static_cast<size_t>(gridPtr->metaValue<float>("ID"));
        newObj.m_vdbSet[metaID] = openvdb::gridPtrCast<DistGridType>(gridPtr);
    });

    // Re-compute numActiveVoxel and world limits
    newObj.tallyActiveVoxel();
    newObj.recomputeLimits();

    return newObj;
}
} // namespace nav
