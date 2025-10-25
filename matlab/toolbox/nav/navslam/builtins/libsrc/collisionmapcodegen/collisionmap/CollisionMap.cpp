/* Copyright 2022 The MathWorks, Inc. */

#ifdef BUILDING_LIBMWCOLLISIONMAPCODEGEN
#include "collisionmapcodegen/CollisionMap.hpp"
#else
#include "CollisionMap.hpp"
#endif

using namespace nav;

CollisionMap::CollisionMap(OcMapPtr ocMapRoot) {
    m_tree = ocMapRoot;
}

bool CollisionMap::isNodeOccupied(const OcNode& node) {
    return m_tree->isNodeOccupied(node);
}

AABB CollisionMap::createAABB(const OcKey& key, const depth_t depth) {
    // Get box size at depth
    double halfLength = m_tree->getNodeSize(depth) * 0.5;

    // Get bottom-left corner of voxel
    auto voxelCenter = m_tree->keyToCoord(key, depth);

    // Shift using voxel size
    double center[3]{static_cast<double>(voxelCenter(0)), static_cast<double>(voxelCenter(1)),
                     static_cast<double>(voxelCenter(2))};
    // Create AABB
    return AABB(halfLength, center);
}

bool CollisionMap::setBBXOnTree(const AABB& box, const depth_t maxQueryDepth) {
    // Get min/max edges of bounding box
    octomap::point3d ptMin = castVec(box.worldMin());
    octomap::point3d ptMax = castVec(box.worldMax());

    // Attempt to convert to keys at desired depth
    bool overlaps = m_tree->coordToKeyChecked(ptMin, maxQueryDepth, m_minKey) &&
        m_tree->coordToKeyChecked(ptMax, maxQueryDepth, m_maxKey);
    
    if (!overlaps) {
        // At least one BBOX corner lies outside the map limits, constrain BBOX to overlap region
        AABB treeLims(voxelSizeAtDepth(1), { 0,0,0 });
        double halfVox = voxelSizeAtDepth(MAX_TREE_DEPTH)/2.0;
        overlaps = treeLims.overlap(box);
        if (overlaps)
        {
            // Floating-point overlap passes, ensure point lies sufficiently inside map bounds
            // so coord->key conversion succeed
            for (size_t i = 0; i < 3; i++) {
                ptMin(static_cast<unsigned int>(i)) = static_cast<float>(std::max(box.worldMin()[i], treeLims.worldMin()[i] + halfVox));
                ptMax(static_cast<unsigned int>(i)) = static_cast<float>(std::min(box.worldMax()[i], treeLims.worldMax()[i] - halfVox));
            }
        }
    }

    // Set bounding region on tree/wrapper
    m_tree->setBBXMin(ptMin);
    m_tree->setBBXMax(ptMax);
    m_tree->useBBXLimit(true);
    m_tree->coordToKeyChecked(ptMin, maxQueryDepth, m_minKey) && 
    m_tree->coordToKeyChecked(ptMax, maxQueryDepth, m_maxKey);

    // Set the depth at which the bounding box has been registered
    m_boxDepth = maxQueryDepth;

    // Return whether BBOX was successfully set
    return overlaps;
}

// Converts a given key to its base-level container at a given level before checking if it is
// contained within the currently set BBOX
bool CollisionMap::inBaseBBX(const OcKey& nodeKey, const depth_t curDepth) {
    auto maxQueryDepth = m_tree->getTreeDepth();
    auto diff = static_cast<unsigned short>(maxQueryDepth - (std::min)(m_boxDepth, curDepth));
    if (diff == 0) {
        return m_tree->inBBX(nodeKey);
    } else {
        // Convert node key to corner keys
        OcKey minNodeKey, maxNodeKey;
        std::tie(minNodeKey, maxNodeKey) = shiftKeyToVoxelCorners(nodeKey, diff);

        // Perform standard AABB check using keys
        for (size_t i = 0; i < 3; i++) {
            if (maxNodeKey.k[i] < m_minKey.k[i] || minNodeKey.k[i] > m_maxKey.k[i]) {
                return false;
            }
        }
        return true;
    }
}

bool nav::CollisionMap::broadPhasePrecheck(const bool broadPhase,
                                           const OcKey& key,
                                           const depth_t depth) {
    return (!broadPhase ? true : inBaseBBX(key, depth));
}

bool CollisionMap::checkCollision_BroadPhase(const AABB& box,
                                             std::vector<OcKey>& keyOut,
                                             std::vector<depth_t>& collDepth) {
    keyOut.clear();
    collDepth.clear();
    // Get leaf iterator covering aabb edges
    if (setBBXOnTree(box)) {
        for (auto it = m_tree->begin_leafs_bbx(m_minKey, m_maxKey), end = m_tree->end_leafs_bbx(); it != end;
         ++it) {
            auto& key = it.getKey();
            depth_t curDepth = it.getDepth();
            bool inBBX = inBaseBBX(key, curDepth);
            bool occupied = m_tree->isNodeOccupied(*it);
            if (occupied && inBBX) {
                // Occupied leaf node found, grab key
                keyOut.push_back(it.getKey());
                collDepth.push_back(it.getDepth());
                return true;
            }
        }
    }
    m_tree->useBBXLimit(false);
    return false;
}

bool CollisionMap::checkCollision_BroadPhaseAtDepth(const AABB& box,
                                                    std::vector<OcKey>& keyOut,
                                                    std::vector<depth_t>& collDepth,
                                                    const depth_t maxQueryDepth) {
    keyOut.clear();
    collDepth.clear();
    octomap::point3d pMin, pMax;
    // Update search region based on geometry AABB and depth
    if (setBBXOnTree(box, maxQueryDepth)) {
        for (auto it = m_tree->begin_tree(static_cast<unsigned char>(maxQueryDepth)),
            end = m_tree->end_tree(); it != end; ++it) {
            depth_t curDepth = it.getDepth();
            if (curDepth == maxQueryDepth || (curDepth < maxQueryDepth && it.isLeaf())) {
                // Get key
                auto& key = it.getKey();

                // Shift key to max depth
                bool inBBX = inBaseBBX(key, curDepth);
                bool occupied = isNodeOccupied(*it);
                if (occupied && inBBX) {
                    // Occupied leaf node found, grab key
                    keyOut.push_back(m_tree->adjustKeyAtDepth(it.getKey(), curDepth));
                    collDepth.push_back(curDepth);
                    m_tree->useBBXLimit(false);
                    return true;
                }
            }
        }
    }
    m_tree->useBBXLimit(false);
    return false;
}

bool CollisionMap::checkCollision_BroadPhaseExhaustive(const AABB& box,
                                                       std::vector<OcKey>& keyOut,
                                                       std::vector<depth_t>& collDepth) {
    keyOut.clear();
    collDepth.clear();
    octomap::point3d pMin, pMax;
    if (setBBXOnTree(box))
    {
        for (auto it = m_tree->begin_leafs_bbx(m_minKey, m_maxKey), end = m_tree->end_leafs_bbx(); it != end;
             ++it) {
            if (isNodeOccupied(*it) && inBaseBBX(it.getKey(), it.getDepth())) {
                // Occupied leaf node found, grab key
                keyOut.push_back(it.getKey());
                collDepth.push_back(it.getDepth());
            }
        }
    }
    m_tree->useBBXLimit(false);
    return !keyOut.empty();
}

bool CollisionMap::checkCollision_BroadPhaseExhaustiveAtDepth(const AABB& box,
                                                              std::vector<OcKey>& keyOut,
                                                              std::vector<depth_t>& collDepth,
                                                              const depth_t maxQueryDepth) {
    keyOut.clear();
    collDepth.clear();
    // Update search region based on geometry AABB and depth
    if (setBBXOnTree(box, maxQueryDepth)) {
        for (auto it = m_tree->begin_tree(static_cast<unsigned char>(maxQueryDepth)),
              end = m_tree->end_tree(); it != end; ++it) {
            depth_t curDepth = it.getDepth();
            if (curDepth == maxQueryDepth || (curDepth < maxQueryDepth && it.isLeaf())) {
                // Get key
                auto& key = it.getKey();

                // Shift key to max depth
                bool inBBX = inBaseBBX(key, curDepth);
                bool occupied = isNodeOccupied(*it);
                if (occupied && inBBX) {
                    // Occupied leaf node found, grab key
                    keyOut.push_back(m_tree->adjustKeyAtDepth(key, it.getDepth()));
                    collDepth.push_back(it.getDepth());
                }
            }
        }
    }
    m_tree->useBBXLimit(false);
    return !keyOut.empty();
}

// Returns the key corresponding to lower-left corner at highest resolution
OcKey CollisionMap::convertToBaseKey(const OcKey& key, const depth_t& currentDepth) {
    depth_t maxQueryDepth = m_tree->getTreeDepth();
    auto diff = static_cast<unsigned short>(maxQueryDepth - currentDepth);
    OcKey outKey = key;
    if (diff != 0) {
        for (size_t i = 0; i < 3; i++) {
            // Erase the last bits, effectively "flooring" the key to the desired level
            outKey.k[i] =
                static_cast<unsigned short>(static_cast<unsigned short>(key.k[i] >> diff) << diff);
        }
    }
    return outKey;
}

double CollisionMap::broadPhaseDistance(AABB& aabb,
                                        double* p1Vec,
                                        double* p2Vec,
                                        depth_t maxQueryDepth) {
    // Brute-force distance calculation
    double distance = nav::INF_DOUBLE;
    double p1Tmp[3], p2Tmp[3];
    // Distance requested
    for (auto it = m_tree->begin_tree(static_cast<unsigned char>(maxQueryDepth)),
              end = m_tree->end_tree();
         it != end; ++it) {
        depth_t curDepth = it.getDepth();
        bool isLeaf = it.isLeaf();
        bool aboveDepth = curDepth < maxQueryDepth;
        if (curDepth == maxQueryDepth || (aboveDepth && isLeaf)) {
            if (isNodeOccupied(*it)) {
                AABB cellAABB = createAABB(it.getKey(), curDepth);
                double curDist = cellAABB.distance(aabb, &p1Tmp[0], &p2Tmp[0]);
                if (curDist < distance) {
                    distance = curDist;
                    std::copy_n(&p1Tmp[0], 3, p1Vec); // TODO: Improve me with swap
                    std::copy_n(&p2Tmp[0], 3, p2Vec);
                }
            }
        }
    }
    return distance;
}
