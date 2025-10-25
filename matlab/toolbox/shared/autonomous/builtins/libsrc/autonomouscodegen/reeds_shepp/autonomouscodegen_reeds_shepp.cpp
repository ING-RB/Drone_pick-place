/* Copyright 2018-2019 The MathWorks, Inc. */

/**
 * @file
 * Implementation of external C-API for ReedsShepp motion primitives.
 * To fully support code generation, note that this file needs to be fully
 * compliant with the C++98 standard.
 */

#include <algorithm> // for std::max

#ifdef BUILDING_LIBMWAUTONOMOUSCODEGEN
#include "autonomouscodegen/autonomouscodegen_reeds_shepp.hpp"
#include "autonomouscodegen/autonomouscodegen_reeds_shepp_api.hpp"
#include "autonomouscodegen/autonomouscodegen_reeds_shepp_functors.hpp"
#include "autonomouscodegen/autonomouscodegen_parallel_range.hpp"
#else
#include "autonomouscodegen_reeds_shepp.hpp"
#include "autonomouscodegen_reeds_shepp_api.hpp"
#include "autonomouscodegen_reeds_shepp_functors.hpp"
#include "autonomouscodegen_parallel_range.hpp"
#endif


EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousReedsSheppSegmentsCodegen_real64(
    const real64_T* startPose,
    const uint32_T numStartPoses,
    const real64_T* goalPose,
    const uint32_T numGoalPoses,
    const real64_T turningRadius,
    const real64_T forwardCost,
    const real64_T reverseCost,
    const boolean_T* allPathTypes,
    const uint32_T numDisabledPathTypes,
    const uint32_T numPaths,
    const boolean_T isOptimal,
    const uint32_T nlhs,
    real64_T* distance,
    real64_T* segmentLen,
    real64_T* segmentType) {

    const uint32_T maxNumPoses = std::max(numStartPoses, numGoalPoses);

    autonomous::reedsshepp::ReedsSheppSegmentsFunctor<real64_T> segmentsFunctor =
        autonomous::reedsshepp::ReedsSheppSegmentsFunctor<real64_T>(
            startPose, numStartPoses, goalPose, numGoalPoses, turningRadius, forwardCost,
            reverseCost, allPathTypes, numDisabledPathTypes, numPaths, isOptimal, nlhs, distance,
            segmentLen, segmentType);

    // Set the grain size to the same value as the maximum range to avoid
    // any range sub-divisions.
    autonomous::ParallelRange<uint32_T> range =
        autonomous::ParallelRange<uint32_T>(0, maxNumPoses, maxNumPoses);

    // Since we are not parallelizing here, simply call the functor
    segmentsFunctor(range);
}


EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousReedsSheppInterpolateCodegen_real64(
    const real64_T* startPose,
    const real64_T* goalPose,
    const real64_T maxDistance,
    const uint32_T numSteps,
    const real64_T turningRadius,
    const real64_T reverseCost,
    real64_T* interpPoses) {


    autonomous::reedsshepp::interpolateRS(startPose, goalPose, maxDistance, numSteps, turningRadius,
                                          reverseCost, interpPoses);
}

EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousReedsSheppInterpolateSegmentsCodegen_real64(
    const real64_T* startPose,
    const real64_T* goalPose,
    const real64_T* samples,
    const uint32_T numSamples,
    const real64_T turningRadius,
    const real64_T* segmentLengths,
    const int32_T* segmentDirections,
    const uint32_T* segmentTypes,
    real64_T* interpPoses,
    real64_T* interpDirections) {
        
    autonomous::reedsshepp::interpolateReedsSheppSegments(startPose, goalPose, samples, numSamples,
                                                  turningRadius, segmentLengths, segmentDirections, segmentTypes,
                                                  interpPoses, interpDirections);
}

EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousReedsSheppDistanceCodegen_real64(
    const real64_T* startPose,
    const uint32_T numStartPoses,
    const real64_T* goalPose,
    const uint32_T numGoalPoses,
    const real64_T turningRadius,
    const real64_T reverseCost,
    real64_T* distance) {

    const uint32_T maxNumPoses = std::max(numStartPoses, numGoalPoses);

    autonomous::reedsshepp::ReedsSheppDistanceFunctor<real64_T> distanceFunctor =
        autonomous::reedsshepp::ReedsSheppDistanceFunctor<real64_T>(
            startPose, numStartPoses, goalPose, numGoalPoses, turningRadius, reverseCost, distance);

    // Set the grain size to the same value as the maximum range to avoid
    // any range sub-divisions.
    autonomous::ParallelRange<uint32_T> range =
        autonomous::ParallelRange<uint32_T>(0, maxNumPoses, maxNumPoses);

    // Since we are not parallelizing here, simply call the functor
    distanceFunctor(range);
}
