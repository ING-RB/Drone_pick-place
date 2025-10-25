/* Copyright 2017-2019 The MathWorks, Inc. */

/**
 * @file
 * Implementation of external C-API for Dubins motion primitives.
 * To fully support code generation, note that this file needs to be fully
 * compliant with the C++98 standard.
 */

#include <algorithm> // for std::max

#ifdef BUILDING_LIBMWAUTONOMOUSCODEGEN
#include "autonomouscodegen/autonomouscodegen_dubins.hpp"
#include "autonomouscodegen/autonomouscodegen_dubins_api.hpp"
#include "autonomouscodegen/autonomouscodegen_dubins_functors.hpp"
#include "autonomouscodegen/autonomouscodegen_parallel_range.hpp"
#else
#include "autonomouscodegen_dubins.hpp"
#include "autonomouscodegen_dubins_api.hpp"
#include "autonomouscodegen_dubins_functors.hpp"
#include "autonomouscodegen_parallel_range.hpp"
#endif


EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousDubinsSegmentsCodegen_real64(
    const real64_T* startPose,
    const uint32_T numStartPoses,
    const real64_T* goalPose,
    const uint32_T numGoalPoses,
    const real64_T turningRadius,
    const boolean_T* allPathTypes,
    const boolean_T isOptimal,
    const uint32_T nlhs,
    real64_T* distance,
    real64_T* segmentLen,
    real64_T* segmentType) {

    const uint32_T maxNumPoses = std::max(numStartPoses, numGoalPoses);

    autonomous::dubins::DubinsSegmentsFunctor<real64_T> segmentsFunctor =
        autonomous::dubins::DubinsSegmentsFunctor<real64_T>(
            startPose, numStartPoses, goalPose, numGoalPoses, turningRadius, allPathTypes,
            isOptimal, nlhs, distance, segmentLen, segmentType);

    // Set the grain size to the same value as the maximum range to avoid
    // any range sub-divisions.
    autonomous::ParallelRange<uint32_T> range =
        autonomous::ParallelRange<uint32_T>(0, maxNumPoses, maxNumPoses);

    // Since we are not parallelizing here, simply call the functor
    segmentsFunctor(range);
}


EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousDubinsInterpolateCodegen_real64(
    const real64_T* startPose,
    const real64_T* goalPose,
    const real64_T maxDistance,
    const uint32_T numSteps,
    const real64_T turningRadius,
    real64_T* interpPoses) {
    
    autonomous::dubins::interpolateDubins(startPose, goalPose, maxDistance, numSteps, turningRadius,
                                          interpPoses);
}

EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousDubinsInterpolateSegmentsCodegen_real64(
    const real64_T* startPose,
    const real64_T* goalPose,
    const real64_T* samples,
    const uint32_T numSamples,
    const real64_T turningRadius,
    const real64_T* segmentLengths,
    const uint32_T* segmentTypes,
    real64_T* interpPoses) {
        
    autonomous::dubins::interpolateDubinsSegments(startPose, goalPose, samples, numSamples,
                                                  turningRadius, segmentLengths, segmentTypes,
                                                  interpPoses);
}

EXTERN_C AUTONOMOUS_CODEGEN_API void autonomousDubinsDistanceCodegen_real64(
    const real64_T* startPose,
    const uint32_T numStartPoses,
    const real64_T* goalPose,
    const uint32_T numGoalPoses,
    const real64_T turningRadius,
    real64_T* distance) {

    const uint32_T maxNumPoses = std::max(numStartPoses, numGoalPoses);

    autonomous::dubins::DubinsDistanceFunctor<real64_T> distanceFunctor =
        autonomous::dubins::DubinsDistanceFunctor<real64_T>(startPose, numStartPoses, goalPose,
                                                            numGoalPoses, turningRadius, distance);

    // Set the grain size to the same value as the maximum range to avoid
    // any range sub-divisions.
    autonomous::ParallelRange<uint32_T> range =
        autonomous::ParallelRange<uint32_T>(0, maxNumPoses, maxNumPoses);

    // Since we are not parallelizing here, simply call the functor
    distanceFunctor(range);
}
