/**
 * @file dpgrid.cpp
 * @brief This file contains the definitions for DPGrid class
 */

/* Copyright 2024 The MathWorks, Inc. */

#ifdef BUILDING_LIBMWDPGRIDCODEGEN
#include "dpgridcodegen/dpgrid.hpp"
#else
// PackNGo has no include file hierarchy
#include "dpgrid.hpp"
#endif


nav::DPGrid::DPGrid(const std::vector<std::vector<bool>>& mapMatrix)
    : _mapMatrix(mapMatrix) {
    _rows = static_cast<uint32_T>(_mapMatrix.size());
    _cols = static_cast<uint32_T>(_mapMatrix[0].size());
    _priorityQueue.reserve(_rows * _cols);
}

void nav::DPGrid::setStart(const uint32_T* start) {
    _start[0] = start[0];
    _start[1] = start[1];
}

void nav::DPGrid::setGoal(const uint32_T* goal) {
    _goal[0] = goal[0];
    _goal[1] = goal[1];

    // Initialize cost matrix to zeros and occupied cells to inf
    nav::DPGrid::initializeCostMatrix();

    // Set goal cost to -eps
    if (!_mapMatrix[_goal[0]][_goal[1]]) {
        _costToGoal[_goal[0]][_goal[1]] = -std::numeric_limits<double>::epsilon();
    }

    // Initialize priority queue with goal cost
    _priorityQueue.emplace_back(_cellData(_goal, -std::numeric_limits<double>::epsilon()));
}

void nav::DPGrid::plan() {

    // Return if cost already converged (>0) or the cell is occupied (=inf)
    if (_costToGoal[_start[0]][_start[1]] > 0 || std::isinf(_costToGoal[_start[0]][_start[1]])) {
        return;
    }

    // Update priority queue heuristic to take into account the new start cell
    for (auto& node : _priorityQueue) {
        auto& current = node.location;
        node.cost = -_costToGoal[current[0]][current[1]] + nav::DPGrid::distance2D(_start, current);
    }

    std::make_heap(_priorityQueue.begin(), _priorityQueue.end(), _minHeapComparator{});

    //-- Run Dynamic Programming  --
    // costToGoal(currentCell) = eps  if currentCell = goalCell, otherwise,
    //                         = min(costToGoal(neighborCells) + transitionCost(currentCell,
    //                               neighborCells))
    //
    // As the costToGoal matrix for the currentCell converges to the optimal cost, the currentCell
    // may be added and removed from the priority queue multiple times. Intermediate costs are
    // cached and subsequently updated as needed. These intermediate costs are stored as negative
    // numbers. The cost is considered converged when its absolute value stops reducing.
    //
    // So to summarize,
    // costToGoal(currentCell) = inf means the cell is already occupied & won't be processed
    // costToGoal(currentCell) = 0 means the cell is initialized but not processed yet
    // costToGoal(currentCell) < 0 means the cell is processed but the cost has not converged yet
    // costToGoal(currentCell) > 0 means the cell cost has converged and won't be further processed
    while (!_priorityQueue.empty()) {

        // Get current element
        auto topNode = _priorityQueue.front();
        std::pop_heap(_priorityQueue.begin(), _priorityQueue.end(), _minHeapComparator{});
        _priorityQueue.pop_back();
        auto& current = topNode.location;
        double currentCost = _costToGoal[current[0]][current[1]];

        // Go to next loop if the current cell already converged
        if (currentCost > 0) {
            continue;
        }

        // Make cost for current cell positive (which we don't need to update this cost again)
        currentCost = -currentCost;
        _costToGoal[current[0]][current[1]] = currentCost;

        // Loop through neighbors of the current cell
        auto neighbors = nav::DPGrid::getValidNeighbors(current);

        for (auto& neighbor : neighbors) {

            // Process the neighbors only if their cost hasn't converged (i.e., existing cost < 0)
            double existingCost = _costToGoal[neighbor[0]][neighbor[1]];
            if (existingCost <= 0) {
                double newCost = currentCost + nav::DPGrid::transitionCost(current, neighbor);

                // Update priority queue for the cells whose new cost estimates are better than the
                // existing cost
                if (existingCost == 0 || -existingCost > newCost) {

                    // Use negative cost in _costToGoal indicating that the cost has not yet
                    // converged
                    _costToGoal[neighbor[0]][neighbor[1]] = -newCost;

                    // Compute updated cost of the neighbor
                    double updatedCost = newCost + nav::DPGrid::distance2D(_start, neighbor);

                    // Update priority queue with new costs
                    _priorityQueue.emplace_back(_cellData(neighbor, updatedCost));

                    std::push_heap(_priorityQueue.begin(), _priorityQueue.end(),
                                   _minHeapComparator{});
                }
            }
        }

        // Exit current cell has reached the _start cell
        if (current[0] == _start[0] && current[1] == _start[1]) {
            break;
        }
    }
}

double nav::DPGrid::getPathCost(const uint32_T* start) {

    // Set _start attribute
    nav::DPGrid::setStart(start);

    // Re-plan for the new start
    nav::DPGrid::plan();

    // When no path exists between _start and _goal, the cost value does not change.
    // We assign infinite cost when no path is found.
    if (_costToGoal[_start[0]][_start[1]] == 0.0) {
        _costToGoal[_start[0]][_start[1]] = std::numeric_limits<double>::infinity();
    }

    return _costToGoal[_start[0]][_start[1]];
}


std::vector<std::array<uint32_T, 2>> nav::DPGrid::getValidNeighbors(
    const std::array<uint32_T, 2>& current) {

    std::array<uint32_T, 2> next;
    std::vector<std::array<uint32_T, 2>> neighbors;
    neighbors.reserve(8); // reserve memory for max 8 neighbors

    // Get valid neighbors
    for (auto& dir : _directions) {

        // Skip cell locations outside the map
        if ((current[0] == 0 && dir[0] < 0) || (current[1] == 0 && dir[1] < 0) ||
            (current[0] == _rows - 1 && dir[0] > 0) || (current[1] == _cols - 1 && dir[1] > 0)) {
            continue;
        }

        next[0] = nav::DPGrid::nextCell(current[0], dir[0]);
        next[1] = nav::DPGrid::nextCell(current[1], dir[1]);

        // Add neighbors if they are not occupied already
        if (!_mapMatrix[next[0]][next[1]]) {
            neighbors.push_back({next[0], next[1]});
        }
    }
    return neighbors;
}


void nav::DPGrid::initializeCostMatrix() {

    // Initialize cost matrix to zeros
    _costToGoal = std::vector<std::vector<double>>(_rows, std::vector<double>(_cols, 0.0));

    // Set cost for occupied cells to inf
    for (uint32_T i = 0; i < _rows; ++i) {
        for (uint32_T j = 0; j < _cols; ++j) {
            if (_mapMatrix[i][j]) {
                _costToGoal[i][j] = std::numeric_limits<double>::infinity();
            }
        }
    }
}


double nav::DPGrid::transitionCost(const std::array<uint32_T, 2>& currentCell,
                                   const std::array<uint32_T, 2>& nextCell) {

    static const double sqrt2 = std::sqrt(2.0);

    // Get distance from current cell to the next cell
    if (currentCell[0] == nextCell[0] || currentCell[1] == nextCell[1]) {
        // cost for orthogonal neighbors
        return 1.0;
    } else {
        // cost for diagonal neighbors
        return sqrt2;
    }
}

double nav::DPGrid::distance2D(const std::array<uint32_T, 2>& cellI,
                               const std::array<uint32_T, 2>& cellJ) {
    // Distance between two given cells in a map
    double d0 = static_cast<double>(cellI[0]) - static_cast<double>(cellJ[0]);
    double d1 = static_cast<double>(cellI[1]) - static_cast<double>(cellJ[1]);
    return std::sqrt(d0 * d0 + d1 * d1);
}


uint32_T nav::DPGrid::nextCell(uint32_T i, int dir) {

    // Current position, i is unsigned and direction, dir is signed

    // When doing i + dir where dir<0, the dir is converted to uint32_T
    // and it does integer wrap around. We want to avoid this, so we
    // do the following:

    uint32_T k;
    if (dir >= 0) {
        k = i + static_cast<uint32_T>(dir);
    } else {
        k = i - static_cast<uint32_T>(-dir);
    }
    return k;
}
