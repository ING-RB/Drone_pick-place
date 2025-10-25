// Copyright 2019-2021 The MathWorks, Inc.

#include <math.h>
#include <vector>

#ifdef BUILDING_LIBMWPLANNINGCODEGEN
    #include "planningcodegen/planningcodegen_cghelpers.hpp"
    #include "planningcodegen/planningcodegen_CommonCSMetric.hpp"
    #include "planningcodegen/planningcodegen_DubinsMetric.hpp"
    #include "planningcodegen/planningcodegen_ReedsSheppMetric.hpp"
    #include "planningcodegen/planningcodegen_SearchTree.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy during test */
    #include "planningcodegen_cghelpers.hpp"
    #include "planningcodegen_CommonCSMetric.hpp"
    #include "planningcodegen_DubinsMetric.hpp"
    #include "planningcodegen_ReedsSheppMetric.hpp"
    #include "planningcodegen_SearchTree.hpp"
#endif

// forward declaration
void setVector(real64_T* data, real64_T sz, std::vector<real64_T>& vec);
void setCArray(std::vector<real64_T>& vec, real64_T* data, std::size_t sz);


// helpers
void setVector(real64_T* data, real64_T sz, std::vector<real64_T>& vec) {
    std::size_t sz_ = static_cast<std::size_t>(sz);
    vec.resize(sz_);
    for (std::size_t k = 0; k < sz_; k++) {
        vec[k] = data[k];
    }
}

void setCArray(std::vector<real64_T>& vec, real64_T* data, std::size_t sz) {
    for (std::size_t k = 0; k < sz; k++) {
        data[k] = vec[k];
    }
}


// exposed C APIs for nav::SearchTree
void* planningcodegen_createTree(real64_T* state, real64_T sz) {
    std::vector<real64_T> vec;
    setVector(state, sz, vec);
    return static_cast<void*>(new nav::SearchTree<real64_T>(vec));
}

void planningcodegen_destructTree(void* tree) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    delete tree_;
}

void planningcodegen_configureCommonCSMetric(void* tree,
                                             const real64_T* topologies,
                                             const real64_T* weights,
                                             real64_T size) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::vector<int32_T> topo_;
    std::size_t sz_ = static_cast<std::size_t>(size);
    topo_.resize(sz_);
    for (std::size_t i = 0; i < sz_; i++) {
        topo_[i] = static_cast<int32_T>(topologies[i]);
    }
    std::vector<real64_T> ws_(weights, weights + sz_);
    tree_->getNNFinder()->purgeMetrics();

    tree_->getNNFinder()->setBuildMetric(
        new nav::CommonCSMetric<real64_T>(tree_->getNodeDim(), topo_, ws_));
    tree_->getNNFinder()->setQueryMetric(
        new nav::CommonCSMetric<real64_T>(tree_->getNodeDim(), topo_, ws_));
}

void planningcodegen_configureDubinsMetric(void* tree, real64_T turningRadius, boolean_T isReversed) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    tree_->getNNFinder()->purgeMetrics();

    tree_->getNNFinder()->setBuildMetric(new nav::DubinsMetric<real64_T>(turningRadius, isReversed));
    tree_->getNNFinder()->setQueryMetric(new nav::DubinsMetric<real64_T>(turningRadius, isReversed));
}

void planningcodegen_configureReedsSheppMetric(void* tree,
                                               real64_T turningRadius,
                                               real64_T reverseCost,
                                               boolean_T isReversed) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    tree_->getNNFinder()->purgeMetrics();

    tree_->getNNFinder()->setBuildMetric(
        new nav::ReedsSheppMetric<real64_T>(turningRadius, reverseCost, isReversed));
    tree_->getNNFinder()->setQueryMetric(
        new nav::ReedsSheppMetric<real64_T>(turningRadius, reverseCost, isReversed));
}


real64_T planningcodegen_getNumNodes(void* tree) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    size_t numNodes = tree_->getNumNodes();
    return static_cast<real64_T>(numNodes);
}


boolean_T planningcodegen_insertNode(void* tree,
                                     real64_T* data,
                                     real64_T sz,
                                     real64_T parentId,
                                     real64_T* newIdx) {
    std::size_t sz_ = static_cast<std::size_t>(sz);
    std::size_t parentId_ = static_cast<std::size_t>(parentId);
    std::size_t newIdx_ = 0;
    std::vector<real64_T> stateVec(data, data + sz_);
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    boolean_T result = tree_->insertNodeByID(parentId_, stateVec, newIdx_);
    *newIdx = static_cast<real64_T>(newIdx_);
    return result;
}

boolean_T planningcodegen_insertNodeWithPrecomputedCost(void* tree,
                                                        real64_T* data,
                                                        real64_T sz,
                                                        real64_T precomputedCost,
                                                        real64_T parentId,
                                                        real64_T* newIdx) {
    std::size_t sz_ = static_cast<std::size_t>(sz);
    std::size_t parentId_ = static_cast<std::size_t>(parentId);
    std::size_t newIdx_ = 0;
    std::vector<real64_T> stateVec(data, data + sz_);
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    boolean_T result =
        tree_->insertNodeByIDWithPrecomputedCost(parentId_, stateVec, precomputedCost, newIdx_);
    *newIdx = static_cast<real64_T>(newIdx_);
    return result;
}


boolean_T planningcodegen_getNodeState(void* tree, real64_T idx, real64_T* state) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::size_t idx_ = static_cast<std::size_t>(idx);
    std::vector<real64_T> stateVec;
    if (tree_->getNode(idx_)) {
        stateVec = tree_->getNode(idx_)->getState();
        setCArray(stateVec, state, tree_->getNodeDim());
        return true;
    } else {
        stateVec.assign(tree_->getNodeDim(), nan(""));
        setCArray(stateVec, state, tree_->getNodeDim());
        return false;
    }
}

real64_T planningcodegen_nearestNeighbor(void* tree, real64_T* state, real64_T sz) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::size_t sz_ = static_cast<std::size_t>(sz);
    std::vector<real64_T> stateVec(state, state + sz_);
    real64_T minDist; // needed as an input arg for internal class method, will be ignored.
    std::size_t idx = tree_->nearestNeighborID(stateVec, minDist);
    return static_cast<real64_T>(idx);
}


void planningcodegen_inspect(void* tree, real64_T* outData) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);

    std::vector<real64_T> outputSeq = tree_->inspect();
    std::size_t nodeDim = tree_->getNodeDim();
    std::size_t numNodesInSeq = outputSeq.size() / nodeDim;

    for (std::size_t k = 0; k < numNodesInSeq; k++) {
        for (std::size_t q = 0; q < nodeDim; q++) {
            outData[k + q * numNodesInSeq] = outputSeq[nodeDim * k + q];
        }
    }
}

real64_T planningcodegen_rewire(void* tree, real64_T nodeIdx, real64_T newParentNodeIdx) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::size_t nodeIdx_ = static_cast<std::size_t>(nodeIdx);
    std::size_t newParentNodeIdx_ = static_cast<std::size_t>(newParentNodeIdx);
    int32_T statusCode = tree_->rewireNodeByID(nodeIdx_, newParentNodeIdx_);
    return static_cast<real64_T>(statusCode);
}

real64_T planningcodegen_rewireWithPrecomputedCost(void* tree,
                                                   real64_T nodeIdx,
                                                   real64_T newParentNodeIdx,
                                                   real64_T precomputedCost) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::size_t nodeIdx_ = static_cast<std::size_t>(nodeIdx);
    std::size_t newParentNodeIdx_ = static_cast<std::size_t>(newParentNodeIdx);
    int32_T statusCode = tree_->rewireNodeByID(nodeIdx_, newParentNodeIdx_, precomputedCost);
    return static_cast<real64_T>(statusCode);
}


void planningcodegen_tracebackToRoot(void* tree,
                                     real64_T nodeId,
                                     real64_T* nodeStateSeq,
                                     real64_T* numNodes) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::size_t id_ = static_cast<std::size_t>(nodeId);
    std::vector<real64_T> outputSeq = tree_->tracebackToRoot(id_);
    std::size_t nodeDim = tree_->getNodeDim();
    *numNodes = static_cast<real64_T>(outputSeq.size() / nodeDim);
    for (std::size_t k = 0; k < outputSeq.size(); k++) {
        nodeStateSeq[k] = outputSeq[k];
    }
}

real64_T planningcodegen_getNodeCostFromRoot(void* tree, real64_T idx) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    return tree_->getNode(static_cast<std::size_t>(idx))->getCostFromRoot();
}

void planningcodegen_setBallRadiusConstant(void* tree, real64_T rc) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    tree_->setBallRadiusConstant(rc);
}

void planningcodegen_setMaxConnectionDistance(void* tree, real64_T dist) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    tree_->setMaxConnectionDistance(dist);
}

void planningcodegen_near(void* tree,
                          real64_T* state,
                          real64_T* nearStateIds,
                          real64_T* numNearStates) {
    nav::SearchTree<real64_T>* tree_ = static_cast<nav::SearchTree<real64_T>*>(tree);
    std::vector<real64_T> stateVec(state, state + tree_->getNodeDim());
    std::vector<std::size_t> indices = tree_->nearNeighborIDs(stateVec);
    *numNearStates = static_cast<real64_T>(indices.size());
    for (std::size_t k = 0; k < indices.size(); k++) {
        nearStateIds[k] = static_cast<real64_T>(indices[k]);
    }
}
