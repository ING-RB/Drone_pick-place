/* Copyright 2022-2023 The MathWorks, Inc. */
#include <array>
#ifdef BUILDING_LIBMWCOLLISIONMAPCODEGEN
#include "collisionmapcodegen/checkMapCollision.hpp"
#include "collisionmapcodegen/collisionmapcodegen_types.hpp"
#else
/* To deal with the fact that PackNGo has no include file hierarchy during test */
#include "checkMapCollision.hpp"
#include "collisionmapcodegen_types.hpp"
#endif

#include <cmath>

namespace nav {
template <typename Iter, typename GeomPtr>
static bool narrowCheck(Iter& it,
                        GeomPtr geomPtr,
                        int computeDistance,
                        double* p1Vec,
                        double* p2Vec,
                        double* distance) {
    // Broadphase collision found, convert node to CollisionGeometry for Narrowphase check
    double edgeSize = it.getSize();
    auto treeBox = shared_robotics::CollisionGeometry(edgeSize, edgeSize, edgeSize);
    treeBox.m_pos.v[0] = it.getX();
    treeBox.m_pos.v[1] = it.getY();
    treeBox.m_pos.v[2] = it.getZ();

    return shared_robotics::intersect(&treeBox, geomPtr, computeDistance, p1Vec, p2Vec, *distance);
}

static double narrowPhaseDistance(nav::CollisionMap& mapObj,
                                  nav::octomapcodegen* tempMap,
                                  const shared_robotics::CollisionGeometry* geom,
                                  double* p1Vec,
                                  double* p2Vec,
                                  depth_t maxQueryDepth) {
    double distance = nav::INF_DOUBLE;
    auto tree = tempMap->getTree();

    for (auto it = tree->begin_tree(static_cast<unsigned char>(maxQueryDepth)),
              end = tree->end_tree();
         it != end; ++it) {
        depth_t curDepth = it.getDepth();
        if (curDepth == maxQueryDepth || (curDepth < maxQueryDepth && it.isLeaf())) {
            if (mapObj.isNodeOccupied(*it)) {
                double p1Tmp[3] = {0, 0, 0}, p2Tmp[3] = {0, 0, 0};
                double tmpDist = nav::INF_DOUBLE;
                int computeDistance = 1;
                // Retain smallest distance
                narrowCheck(it, geom, computeDistance, &p1Tmp[0], &p2Tmp[0], &tmpDist);
                if (tmpDist < distance) {
                    distance = tmpDist;
                    std::copy_n(&p1Tmp[0], 3, p1Vec); // TODO: Improve me with swap
                    std::copy_n(&p2Tmp[0], 3, p2Vec);
                }
            }
        }
    }
    return distance;
}

COLLISIONMAP_CODEGEN_API bool octomapCheckCollision_impl(void* map,
                                                         const void* geom,
                                                         double& distance,
                                                         const bool exhaustive,
                                                         const bool narrowPhase,
                                                         const bool broadPhase,
                                                         const depth_t maxQueryDepth,
                                                         double* p1Vec,
                                                         double* p2Vec,
                                                         std::vector<std::array<double, 3>>& ctrs,
                                                         std::vector<double>& edgeLength,
                                                         double* center,
                                                         double* pMin,
                                                         double* pMax) {
    nav::octomapcodegen* tempMap = static_cast<nav::octomapcodegen*>(map);
    const shared_robotics::CollisionGeometry* tempGeom =
        static_cast<const shared_robotics::CollisionGeometry*>(geom);

    // Wrap in CollisionObject interface
    nav::CollisionMap mapObj(tempMap->getTree());
    bool collisionFound = false;
    std::vector<depth_t> collDepth;
    std::vector<OcKey> keys;

    AABB aabb;
    nav::computeGlobalBV(tempGeom, aabb);
    std::copy_n(aabb.m_localOrigin.begin(), 3, center);
    std::copy_n(aabb.worldMin().begin(), 3, pMin);
    std::copy_n(aabb.worldMax().begin(), 3, pMax);

    bool computeDistance = distance != 0;
    if (!narrowPhase) {
        if (!exhaustive) {
            if (maxQueryDepth == nav::MAX_TREE_DEPTH) {
                collisionFound = mapObj.checkCollision_BroadPhase(aabb, keys, collDepth);
            } else {
                collisionFound =
                    mapObj.checkCollision_BroadPhaseAtDepth(aabb, keys, collDepth, maxQueryDepth);
            }
        } else {
            if (maxQueryDepth == nav::MAX_TREE_DEPTH) {
                collisionFound = mapObj.checkCollision_BroadPhaseExhaustive(aabb, keys, collDepth);
            } else {
                collisionFound = mapObj.checkCollision_BroadPhaseExhaustiveAtDepth(
                    aabb, keys, collDepth, maxQueryDepth);
            }
        }
        distance = (!collisionFound && computeDistance)
                       ? mapObj.broadPhaseDistance(aabb, p1Vec, p2Vec, maxQueryDepth)
                       : nav::INF_DOUBLE;
    } else {
        distance = nav::INF_DOUBLE;
        // void* c_geom = const_cast<void*>(geom);
        if (!exhaustive) {
            if (maxQueryDepth == nav::MAX_TREE_DEPTH) {
                collisionFound =
                    checkCollision_FullCheck_EarlyExit(map, geom, aabb, broadPhase, computeDistance,
                                                       p1Vec, p2Vec, keys, collDepth, &distance);
            } else {
                collisionFound = checkCollision_FullCheck_EarlyExitAtDepth(
                    map, geom, aabb, broadPhase, computeDistance, p1Vec, p2Vec, keys, collDepth,
                    maxQueryDepth, &distance);
            }
        } else {
            if (maxQueryDepth == nav::MAX_TREE_DEPTH) {
                collisionFound =
                    checkCollision_FullCheck_Exhaustive(map, geom, aabb, broadPhase, computeDistance,
                                                        p1Vec, p2Vec, keys, collDepth, &distance);
            } else {
                collisionFound = checkCollision_FullCheck_ExhaustiveAtDepth(
                    map, geom, aabb, broadPhase, computeDistance, p1Vec, p2Vec, keys, collDepth,
                    maxQueryDepth, &distance);
            }
        }
        if (!collisionFound && computeDistance && distance == nav::INF_DOUBLE) {
            // Broadphase bounding box did not intersect with any cells, we must brute-force the
            // distance calculation
            distance = narrowPhaseDistance(mapObj, tempMap, tempGeom, p1Vec, p2Vec, maxQueryDepth);
        }
    }

    // Convert keys and depths to size/centers
    for (size_t i = 0; i < keys.size(); i++) {
        edgeLength.push_back(mapObj.voxelSizeAtDepth(collDepth[i]));
        auto tmp = tempMap->getTree()->keyToCoord(keys[i], collDepth[i]);
        std::array<double, 3> pt = {{static_cast<double>(tmp(0)), static_cast<double>(tmp(1)),
                                     static_cast<double>(tmp(2))}};

        ctrs.push_back(pt);
    }

    return collisionFound;
}

bool checkCollision_FullCheck_EarlyExit(void* map,
    const void* geom,
    const AABB& geomAABB,
    const bool broadPhase,
    const int& computeDistance,
    double* p1Vec,
    double* p2Vec,
    std::vector<OcKey>& key,
    std::vector<depth_t>& collDepth,
    double* distance) {

    key.clear();
    collDepth.clear();
    nav::octomapcodegen* tempMap = static_cast<nav::octomapcodegen*>(map);
    const shared_robotics::CollisionGeometry* tempGeom =
        static_cast<const shared_robotics::CollisionGeometry*>(geom);
    auto tree = tempMap->getTree();

    // Wrap in CollisionObject interface
    nav::CollisionMap mapObj(tempMap->getTree());

    // Update search region based on geometry AABB and depth
    if (mapObj.setBBXOnTree(geomAABB)) {
        for (auto it = tree->begin_leafs_bbx(mapObj.minKey(), mapObj.maxKey()), end = tree->end_leafs_bbx(); it != end;
         ++it) {
            // Get key and check occupancy
            auto& nodeKey = it.getKey();
            bool occupied = tree->isNodeOccupied(*it);
            auto curDepth = it.getDepth();

            if (occupied && mapObj.broadPhasePrecheck(broadPhase, nodeKey, curDepth)) {
                double p1Tmp[3], p2Tmp[3], tmpDist;
                bool collisionFound =
                    narrowCheck(it, tempGeom, computeDistance, p1Tmp, p2Tmp, &tmpDist);
                if (tmpDist < *distance) {
                    *distance = tmpDist;
                    std::copy_n(&p1Tmp[0], 3, p1Vec); // TODO: Improve me with swap
                    std::copy_n(&p2Tmp[0], 3, p2Vec);
                }
                // BroadPhase collision encountered, verify with NarrowPhase check
                if (collisionFound) {
                    key.push_back(nodeKey);
                    collDepth.push_back(curDepth);
                    tree->useBBXLimit(false);
                    return true;
                }
            }
        }
    }
    tree->useBBXLimit(false);
    return false;
}

bool checkCollision_FullCheck_EarlyExitAtDepth(void* map,
                                               const void* geom,
                                               const AABB& geomAABB,
                                               const bool broadPhase,
                                               const int& computeDistance,
                                               double* p1Vec,
                                               double* p2Vec,
                                               std::vector<OcKey>& keyOut,
                                               std::vector<depth_t>& collDepth,
                                               const depth_t maxQueryDepth,
                                               double* distance) {
    keyOut.clear();
    collDepth.clear();

    nav::octomapcodegen* tempMap = static_cast<nav::octomapcodegen*>(map);
    const shared_robotics::CollisionGeometry* tempGeom =
        static_cast<const shared_robotics::CollisionGeometry*>(geom);
    auto tree = tempMap->getTree();

    // Wrap in CollisionObject interface
    nav::CollisionMap mapObj(tempMap->getTree());

    // Update search region based on geometry AABB and depth
    if (mapObj.setBBXOnTree(geomAABB, maxQueryDepth)) {
        for (auto it = tree->begin_tree(static_cast<unsigned char>(maxQueryDepth)),
              end = tree->end_tree(); it != end; ++it) {
            depth_t curDepth = it.getDepth();
            if (curDepth == maxQueryDepth || (curDepth < maxQueryDepth && it.isLeaf())) {
                // Get key and check occupancy
                auto nodeKey = it.getKey();
                bool occupied = tree->isNodeOccupied(*it);

                if (occupied && mapObj.broadPhasePrecheck(broadPhase, nodeKey, curDepth)) {
                    double p1Tmp[3], p2Tmp[3], tmpDist;
                    bool collisionFound =
                        narrowCheck(it, tempGeom, computeDistance, p1Tmp, p2Tmp, &tmpDist);
                    if (tmpDist < *distance) {
                        *distance = tmpDist;
                        std::copy_n(&p1Tmp[0], 3, p1Vec); // TODO: Improve me with swap
                        std::copy_n(&p2Tmp[0], 3, p2Vec);
                    }
                    if (collisionFound) {
                        keyOut.push_back(nodeKey);
                        collDepth.push_back(curDepth);
                        tree->useBBXLimit(false);
                        return true;
                    }
                }
            }
        }
    }
    tree->useBBXLimit(false);
    return false;
}

bool checkCollision_FullCheck_Exhaustive(void* map,
                                         const void* geom,
                                         const AABB& geomAABB,
                                         const bool broadPhase,
                                         const int& computeDistance,
                                         double* p1Vec,
                                         double* p2Vec,
                                         std::vector<OcKey>& keys,
                                         std::vector<depth_t>& collDepth,
                                         double* distance) {
    keys.clear();
    collDepth.clear();

    nav::octomapcodegen* tempMap = static_cast<nav::octomapcodegen*>(map);
    const shared_robotics::CollisionGeometry* tempGeom =
        static_cast<const shared_robotics::CollisionGeometry*>(geom);
    auto tree = tempMap->getTree();

    // Wrap in CollisionObject interface
    nav::CollisionMap mapObj(tempMap->getTree());

    // Update search region based on geometry AABB and depth
    if (mapObj.setBBXOnTree(geomAABB))
    {
        for (auto it = tree->begin_leafs_bbx(mapObj.minKey(), mapObj.maxKey()), end = tree->end_leafs_bbx(); it != end;
         ++it) {
            // Get key and check occupancy
            auto& nodeKey = it.getKey();
            bool occupied = tree->isNodeOccupied(*it);
            auto curDepth = it.getDepth();

            if (occupied && mapObj.broadPhasePrecheck(broadPhase, nodeKey, curDepth)) {
                double tmpDist;
                double p1Tmp[3], p2Tmp[3];
                bool collisionFound =
                    narrowCheck(it, tempGeom, computeDistance, p1Tmp, p2Tmp, &tmpDist);
                if (collisionFound) {
                    keys.push_back(it.getKey());
                    collDepth.push_back(it.getDepth());
                    *distance = -nav::INF_DOUBLE;
                } else if (*distance != -nav::INF_DOUBLE && tmpDist < *distance) {
                    *distance = tmpDist;
                    std::copy_n(&p1Tmp[0], 3, p1Vec); // TODO: Improve me with swap
                    std::copy_n(&p2Tmp[0], 3, p2Vec);
                }
            }
        }
    }
    tree->useBBXLimit(false);
    return !keys.empty();
}

bool checkCollision_FullCheck_ExhaustiveAtDepth(void* map,
                                                const void* geom,
                                                const AABB& geomAABB,
                                                const bool broadPhase,
                                                const int& computeDistance,
                                                double* p1Vec,
                                                double* p2Vec,
                                                std::vector<OcKey>& keys,
                                                std::vector<depth_t>& collDepth,
                                                const depth_t maxQueryDepth,
                                                double* distance) {
    keys.clear();
    collDepth.clear();

    nav::octomapcodegen* tempMap = static_cast<nav::octomapcodegen*>(map);
    const shared_robotics::CollisionGeometry* tempGeom =
        static_cast<const shared_robotics::CollisionGeometry*>(geom);
    auto tree = tempMap->getTree();

    // Wrap in CollisionObject interface
    nav::CollisionMap mapObj(tempMap->getTree());

    // Update search region based on geometry AABB and depth
    if (mapObj.setBBXOnTree(geomAABB, maxQueryDepth)) {
        for (auto it = tree->begin_tree(static_cast<unsigned char>(maxQueryDepth)),
              end = tree->end_tree(); it != end; ++it) {
            depth_t curDepth = it.getDepth();
            if (curDepth == maxQueryDepth || (curDepth < maxQueryDepth && it.isLeaf())) {
                // Get key and check occupancy
                auto nodeKey = it.getKey();
                bool occupied = tree->isNodeOccupied(*it);

                if (occupied && mapObj.broadPhasePrecheck(broadPhase, nodeKey, curDepth)) {
                    double p1Tmp[3], p2Tmp[3], tmpDist;
                    bool collisionFound =
                        narrowCheck(it, tempGeom, computeDistance, p1Tmp, p2Tmp, &tmpDist);
                    if (collisionFound) {
                        keys.push_back(it.getKey());
                        collDepth.push_back(curDepth);
                        *distance = -nav::INF_DOUBLE;
                    } else if (*distance != -nav::INF_DOUBLE && tmpDist < *distance) {
                        *distance = tmpDist;
                        std::copy_n(&p1Tmp[0], 3, p1Vec); // TODO: Improve me with swap
                        std::copy_n(&p2Tmp[0], 3, p2Vec);
                    }
                }
            }
        }
    }

    bool collisionFound = !keys.empty();
    tree->useBBXLimit(false);
    *distance = (collisionFound) ? -nav::INF_DOUBLE : *distance;
    return collisionFound;
}

void computeBV(const shared_robotics::CollisionGeometry* geom, nav::AABB& bbox) {
    switch (geom->getEnumType()) {
        case shared_robotics::CollisionGeometry::Type::Box:
            bbox.m_localMin = {-geom->getX() * 0.5, -geom->getY() * 0.5, -geom->getZ() * 0.5};
            bbox.m_localMax = {geom->getX() * 0.5, geom->getY() * 0.5, geom->getZ() * 0.5};
            break;
        case shared_robotics::CollisionGeometry::Type::Sphere:
            bbox.m_localMin = {-geom->getRadius(), -geom->getRadius(), -geom->getRadius()};
            bbox.m_localMax = {geom->getRadius(), geom->getRadius(), geom->getRadius()};
            break;
        case shared_robotics::CollisionGeometry::Type::Cylinder:
            bbox.m_localMin = {-geom->getRadius(), -geom->getRadius(), -geom->getHeight() * 0.5};
            bbox.m_localMax = {geom->getRadius(), geom->getRadius(), geom->getHeight() * 0.5};
            break;
        case shared_robotics::CollisionGeometry::Type::ConvexMesh:
        case shared_robotics::CollisionGeometry::Type::ConvexMeshFull: {
            constexpr double absMin = std::numeric_limits<double>::min();
            constexpr double absMax = std::numeric_limits<double>::max();
            bbox.m_localMin = {absMax, absMax, absMax};
            bbox.m_localMax = {absMin, absMin, absMin};
            for (depth_t n = 0; n < geom->getNumVertices(); n++) {
                for (size_t i = 0; i < 3; i++) {
                    bbox.m_localMin[i] = (bbox.m_localMin[i] < geom->getVertices()[n].v[i])
                                             ? bbox.m_localMin[i]
                                             : geom->getVertices()[n].v[i];
                    bbox.m_localMax[i] = (bbox.m_localMax[i] > geom->getVertices()[n].v[i])
                                             ? bbox.m_localMax[i]
                                             : geom->getVertices()[n].v[i];
                }
            }
            break;
        }
        case shared_robotics::CollisionGeometry::Type::Capsule: {
            auto rad = geom->getRadius();
            auto height = geom->getHeight() * 0.5 + rad;
            bbox.m_localMin = {-rad, -rad, -height};
            bbox.m_localMax = {rad, rad, height};
            break;
        }
    }
}

std::pair<ccd_vec3_t, ccd_vec3_t> cylBounds(const shared_robotics::CollisionGeometry* cyl) {

    std::pair<ccd_vec3_t, ccd_vec3_t> out;
    auto q = cyl->m_quat;

    // Transform the U,V basis vectors and face-center point
    ccd_vec3_t U{ 1,0,0 }, V{ 0,1,0 };
    out.second = { 0,0,cyl->getHeight() * 0.5 };
    ccdQuatRotVec(&U, &q);
    ccdQuatRotVec(&V, &q);
    ccdQuatRotVec(&out.second, &q);
    ccd_real_t th, p, r = cyl->getRadius();

    // Calculate the extrema value in each dimension
    for (unsigned int i = 0; i < 3u; i++) {
        th = (std::atan2)(V.v[i], U.v[i]);
        p = r * (std::cos(th) * U.v[i] + std::sin(th) * V.v[i]);
        out.second.v[i] = CCD_FABS(out.second.v[i]) + CCD_FABS(p);
        out.first.v[i] = -out.second.v[i];
    }
    return out;
}

std::pair<ccd_vec3_t, ccd_vec3_t> capBounds(const shared_robotics::CollisionGeometry* cap) {

    std::pair<ccd_vec3_t, ccd_vec3_t> out;
    auto q = cap->m_quat;

    // Transform point lying at center of one cylinder face
    ccd_vec3_t pt{ 0,0, cap->getHeight() / 2.0 };
    ccdQuatRotVec(&pt, &q);

    // AABB spans both sides of symmetric capsule
    for (unsigned int i = 0; i < 3u; i++)
    {
        pt.v[i] += ccdSign(pt.v[i]) * cap->getRadius();
        out.second.v[i] = CCD_FABS(pt.v[i]);
        out.first.v[i] = -out.second.v[i];
    }
    return out;
}

std::pair<ccd_vec3_t, ccd_vec3_t> boundRotatedPoints(const std::vector<ccd_vec3_t> &v, const ccd_quat_t * q) {
    ccd_vec3_t pMin{ INF_DOUBLE,INF_DOUBLE,INF_DOUBLE }, pMax{ -INF_DOUBLE,-INF_DOUBLE,-INF_DOUBLE };
    ccd_vec3_t curPt{ 0,0,0 };
    for (unsigned int ip = 0; ip < v.size(); ip++) {
        // Transform point
        ccdVec3Copy(&curPt, &v[ip]);
        ccdQuatRotVec(&curPt, q);

        // Keep track of smallest/largest values
        for (unsigned int i = 0; i < 3; i++)
        {
            pMin.v[i] = CCD_FMIN(pMin.v[i], curPt.v[i]);
            pMax.v[i] = CCD_FMAX(pMax.v[i], curPt.v[i]);
        }
    }
    return std::pair<ccd_vec3_t, ccd_vec3_t>(pMin, pMax);
}

std::pair<ccd_vec3_t, ccd_vec3_t> boxBounds(const shared_robotics::CollisionGeometry* box) {
    std::vector<ccd_vec3_t> v;
    auto q = box->m_quat;
    auto x = box->getX() / 2, y = box->getY() / 2, z = box->getZ() / 2;
    v.push_back(ccd_vec3_t({ x,  y,  z }));
    v.push_back(ccd_vec3_t({ x, -y,  z }));
    v.push_back(ccd_vec3_t({-x,  y,  z }));
    v.push_back(ccd_vec3_t({-x, -y,  z }));
    v.push_back(ccd_vec3_t({ x,  y, -z }));
    v.push_back(ccd_vec3_t({ x, -y, -z }));
    v.push_back(ccd_vec3_t({-x,  y, -z }));
    v.push_back(ccd_vec3_t({-x, -y, -z }));

    // Rotate points and grab min/max corner
    return boundRotatedPoints(v, &q);
}

void computeRotatedBV(const shared_robotics::CollisionGeometry* geom, AABB& bbox) {
    // Extract quaternion
    auto q = geom->m_quat;
    ccd_vec3_t pMin{ 0,0,0 }, pMax{ 0,0,0 };
    std::vector<ccd_vec3_t> v;
    switch (geom->getEnumType()) {
        case shared_robotics::CollisionGeometry::Type::Sphere:
        // Rotation has no effect on sphere, AABB is simply -/+ radius in each dimension
            pMin = ccd_vec3_t{ -geom->getRadius(), -geom->getRadius(), -geom->getRadius() };
            pMax = ccd_vec3_t{  geom->getRadius(),  geom->getRadius(),  geom->getRadius() };
            break;
        case shared_robotics::CollisionGeometry::Type::Cylinder:
            std::tie(pMin,pMax) = cylBounds(geom);
            break;
        case shared_robotics::CollisionGeometry::Type::Capsule:
            std::tie(pMin,pMax) = capBounds(geom);
            break;
        case shared_robotics::CollisionGeometry::Type::Box:
            std::tie(pMin,pMax) = boxBounds(geom);
            break;
        case shared_robotics::CollisionGeometry::Type::ConvexMesh:
        case shared_robotics::CollisionGeometry::Type::ConvexMeshFull:
            v = geom->getVertices();
            std::tie(pMin,pMax) = boundRotatedPoints(v, &q);
    }

    // Set local min/max
    bbox.m_localMin = { pMin.v[0], pMin.v[1], pMin.v[2] };
    bbox.m_localMax = { pMax.v[0], pMax.v[1], pMax.v[2] };
}

void computeGlobalBV(const shared_robotics::CollisionGeometry* geom,
                     nav::AABB& bbox) {
    // Compute local AABB
    if (geom->m_quat.q[3] == 1)
        computeBV(geom, bbox);
    else {
        computeRotatedBV(geom, bbox);
    }

    // Translate local AABB using pos/quat of geometry
    bbox.m_localOrigin[0] = geom->m_pos.v[0];
    bbox.m_localOrigin[1] = geom->m_pos.v[1];
    bbox.m_localOrigin[2] = geom->m_pos.v[2];
}

} // namespace nav
