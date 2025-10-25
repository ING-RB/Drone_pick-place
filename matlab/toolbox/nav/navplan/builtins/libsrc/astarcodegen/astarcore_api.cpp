/**
 * @file AStarCore codegen C interface
 * @brief This file contains the definitions for C-API interfaces
 */

/* Copyright 2022 The MathWorks, Inc. */

#ifdef BUILDING_LIBMWASTARCODEGEN
#include "astarcodegen/astarcore.hpp"
#include "astarcodegen/astarcore_api.hpp"
#else
#include "astarcore.hpp"
#include "astarcore_api.hpp"
#endif


EXTERN_C ASTARCORE_CODEGEN_API void* astarcore_construct() {
    // Construct AStarCore object
    return static_cast<void*>(new nav::AStarCore());
}

EXTERN_C ASTARCORE_CODEGEN_API void astarcore_destruct(void* astarObj) {
    // Destruct AStarCore object
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    if (astar != nullptr) {
        delete astar;
    }
}

EXTERN_C ASTARCORE_CODEGEN_API void astarcore_setStart(void *astarObj, const uint32_T start) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Set goal for A* search
    astar->setStart(start); 
}

EXTERN_C ASTARCORE_CODEGEN_API void astarcore_setGoal(void* astarObj, const uint32_T goal) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Set goal for A* search
    astar->setGoal(goal);
}

EXTERN_C ASTARCORE_CODEGEN_API uint32_T astarcore_getCurrentNode(void* astarObj) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Get current node from A* search loop
    return astar->getCurrentNode();
}


EXTERN_C ASTARCORE_CODEGEN_API void astarcore_loopThroughNeighbors(void* astarObj, const uint32_T nSize,
                                                                  const uint32_T* neighbors,
                                                                  const real64_T* transitionCosts, 
                                                                  const real64_T* heuristicCosts) {

    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);     
    // Convert array inputs to vectors
    std::vector<uint32_T> neighborsVec(neighbors, neighbors+nSize);
    std::vector<real64_T> transitionCostsVec(transitionCosts, transitionCosts+nSize);
    std::vector<real64_T> heuristicCostsVec(heuristicCosts, heuristicCosts+nSize);
    // Loop through neighbors to update the priority queue
    astar->loopThroughNeighbors(neighborsVec, transitionCostsVec, heuristicCostsVec);
}


EXTERN_C ASTARCORE_CODEGEN_API void astarcore_getPath(void* astarObj, real64_T* path) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Get path output after A* search is complete
    std::vector<uint32_T>pathVec(astar->getPath());
    // Copy the "pathVec" to output array "path"    
    std::transform(pathVec.begin(), pathVec.end(), path,\
             [](const uint32_T x) {return static_cast<real64_T>(x);});//Cannot pass uint32_T* array to MATLAB, gives error during MEX,
                                                                      // hence casting it to real64_T* array
}

 
EXTERN_C ASTARCORE_CODEGEN_API void astarcore_getExploredNodes(void* astarObj, real64_T* exploredNodes) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Get path output after A* search is complete
    std::vector<uint32_T>exploredNodesVec(astar->getExploredNodes());
    // Copy the "exploredNodes vector to output array "exploredNodes"       
    std::transform(exploredNodesVec.begin(), exploredNodesVec.end(), exploredNodes,\
                  [](const uint32_T x) {return static_cast<real64_T>(x);}); //Cannot pass uint32_T* array to MATLAB, gives error during MEX,
                                                                            // hence casting it to real64_T* array
}

EXTERN_C ASTARCORE_CODEGEN_API uint32_T astarcore_getPathSize(void* astarObj) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Get path size after the A* search is complete
    return static_cast<uint32_T>(astar->getPath().size()); //Cannot pass size_t or mwsize to MATLAB, gives error during MEX,
                                                          // hence casting it to uint32_T
}

EXTERN_C ASTARCORE_CODEGEN_API uint32_T astarcore_getNumExploredNodes(void* astarObj) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Get number of explored nodes after the A* search is complete
    return static_cast<uint32_T>(astar->getExploredNodes().size()); //Cannot pass size_t or mwsize to MATLAB, gives error during MEX,
                                                                    // hence casting it to uint32_T
}

EXTERN_C ASTARCORE_CODEGEN_API real64_T astarcore_getPathCost(void* astarObj) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Get path cost after the A* search is complete
    return astar->getPathCost();
}


EXTERN_C ASTARCORE_CODEGEN_API boolean_T astarcore_stopCondition(void* astarObj) {
    nav::AStarCore* astar = static_cast<nav::AStarCore*>(astarObj);
    // Know if stop condition is reached or not
    return astar->stopCondition();
}
