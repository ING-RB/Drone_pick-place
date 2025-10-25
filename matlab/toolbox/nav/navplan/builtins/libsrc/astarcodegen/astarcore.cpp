/**
 * @file astarcore.cpp
 * @brief This file contains the definitions for AStarCore class
 */

/* Copyright 2022-2023 The MathWorks, Inc. */

#ifdef BUILDING_LIBMWASTARCODEGEN
#include "astarcodegen/astarcore.hpp"
#else
// PackNGo has no include file hierarchy
#include "astarcore.hpp"
#endif


void nav::AStarCore::setStart(const nodeID& start){
    
    _start = start;     // Initialize _start property    
    real64_T gCost = 0.0;      // Initialize gCost
    boolean_T closed = false;        // Start node is in openSet hence closed=false

    // Add start node and gCost to priority queue
    _openSet.push({gCost, _start});     
    
    // Set parent node of start to 0
    _cameFrom[_start] = 0;   

    // Update node data with gCost and closed flag 
    _nodeData[_start] = {gCost, closed};
}


void nav::AStarCore::setGoal(const nodeID& goal){
    _goal = goal;  // Initialize _goal property
}


uint32_T nav::AStarCore::getCurrentNode(){
    

    // Check if openSet is empty 
    if (_openSet.empty()){
        return 0;   // current node is 0
    }

    // Get top element from priority queue
    auto top = _openSet.top();
    _current = top.second;    

    // Remove the current node from openSet 
    _openSet.pop(); 

    // If current node is in closedSet, pop the next current node
    boolean_T closed =  this->inClosedSet(_current);    
    if(closed){
        this->getCurrentNode();
    }

    // Check if goal is reached
    if (_current == _goal){
        _goalReached = true;
    }

    // Mark the current node as closed in the nodeData
    closed = true;
    _nodeData[_current].second = closed;        
    return _current;    
}


void nav::AStarCore::loopThroughNeighbors(const std::vector<nodeID>& neighbors,
                                const std::vector<real64_T>& transitionCosts,
                                const std::vector<real64_T>& heuristicCosts){
    if (_goalReached){
        return;
    }

    boolean_T closed;
    real64_T tentativegCost, gCost, fCost;

    // Get current node's gCost
    real64_T gCostCurrent = _nodeData[_current].first;

    // Loop through each neighbor
    for(uint32_T i=0; i<neighbors.size(); ++i){
        
        // Tentative gCost of the neighbor
        tentativegCost = gCostCurrent + transitionCosts[i];

        // Get previous gCost of neighbor
        // If the neighbor key is not present, we get 0 values
        gCost = _nodeData[neighbors[i]].first;

        // If nodeData doesn't contain the neighbor &
        // If the tentative gCost is less than existing gCost
        if ((gCost==0) || (tentativegCost < gCost)){

            closed = inClosedSet(neighbors[i]);
            
            // Update the neighbor node data            
            _nodeData[neighbors[i]] = {tentativegCost, closed};

            // Update the parent node of the neighbor
            _cameFrom[neighbors[i]] = _current;

            // Compute the total expected fCost for the neighbor
            fCost = tentativegCost + heuristicCosts[i];

            //If the node has not been explored then,
            //push the neighbor node to the priority queue
            if(!closed){
                _openSet.push({fCost, neighbors[i]});
            }                        
        }        
    }    
}


boolean_T nav::AStarCore::inClosedSet(const nodeID& node){

    boolean_T closed = false;
    if (_nodeData.find(node) != _nodeData.end()){
        // key found
        closed = _nodeData[node].second;        
    }
    return closed;
}


std::vector<nav::AStarCore::nodeID> nav::AStarCore::getPath(){
    
    // If goal is not reached then don't do anything
    if (_current != _goal){
        return {0};
    }

    // Reconstructed path vector after A* search is complete
    std::vector<nodeID> path; 
    uint32_T ind = _current;
    // Compute path    
    path.push_back(ind);
    while(ind != _start){
        ind = _cameFrom[ind];
        path.push_back(ind);
    }    
    // Reverse to reorder from start to goal
    std::reverse(path.begin(), path.end());

    return path;
}


std::vector<nav::AStarCore::nodeID> nav::AStarCore::getExploredNodes(){
    
    // Explored nodeIDs during the search
    std::vector<nodeID> exploredNodes;  

    // Return {0} if no nodes are explored
    if(_nodeData.empty()){
        exploredNodes.push_back(uint32_T(0));
        return exploredNodes;
    }

      
    // Traverse the nodeData containing explored nodes and collect the keys
    for(auto node: _nodeData){
        exploredNodes.push_back(node.first);
    }

    return exploredNodes;

}


real64_T nav::AStarCore::getPathCost(){  
    // gCost in nodeData for goal contains the final path cost
    
    if (_nodeData.find(_goal) == _nodeData.end()){
        // Return nan when goal is not reached
        return nan("");
    }
    else{
        // Return the path cost stored in _nodeData
        return _nodeData[_goal].first;
    }
}


boolean_T nav::AStarCore::stopCondition() const{

    // Stop if openSet is empty or goal is reached
    if (_openSet.empty() || _goalReached){  
        return true;
    }
    else{
        return false;
    }
}

