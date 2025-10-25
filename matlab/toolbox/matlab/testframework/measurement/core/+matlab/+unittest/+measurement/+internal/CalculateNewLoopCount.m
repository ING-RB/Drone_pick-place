function outStruct = CalculateNewLoopCount(currLoopCount,...
    currDuration,estimationPhaseCount,minTime,estimating, repeatIndex,...
    maxEstimationPhaseCount,testName, hasConflict, DetectedLoopingConflictBefore)

% Copyright 2024 The MathWorks, Inc.

arguments
    currLoopCount (1,1) double {mustBePositive, mustBeInteger}
    currDuration (1,1) double {mustBeNonnegative}
    estimationPhaseCount (1,1) double {mustBeNonnegative, mustBeInteger}
    minTime (1,1) double {mustBeNonnegative}
    estimating (1,1) logical
    repeatIndex (1,1) double {mustBeNonnegative, mustBeInteger}
    maxEstimationPhaseCount (1,1) double {mustBeNonnegative, mustBeInteger}
    testName (1,1) string
    hasConflict (1,1) logical
    DetectedLoopingConflictBefore (1,1) logical
end

outStruct.LoopCount = currLoopCount;
outStruct.Estimating = estimating;
outStruct.EstimationPhaseCount = estimationPhaseCount;
outStruct.DetectedLoopingConflictBefore = DetectedLoopingConflictBefore;

if (hasConflict)
    if (~DetectedLoopingConflictBefore)
        outStruct.LoopCount = 1;
        outStruct.Estimating = false;
        outStruct.DetectedLoopingConflictBefore = true;
        outStruct.EstimationPhaseCount = repeatIndex - 1;
    end
else
    if (currDuration < minTime)
        diff = minTime - currDuration;
        singleLoopCost = currDuration / currLoopCount;

        outStruct.LoopCount = currLoopCount + ceil(diff / singleLoopCost);

        if (estimating && repeatIndex > maxEstimationPhaseCount)
            outStruct.Estimating = false;
            outStruct.EstimationPhaseCount = maxEstimationPhaseCount;
            warning(message("MATLAB:unittest:measurement:MeasurementPlugin:ExceededMaxEstimationCount",...
                testName, maxEstimationPhaseCount));
        end
    else
        if (estimating)
            outStruct.Estimating = false;
            outStruct.EstimationPhaseCount = repeatIndex - 1;
        end
    end
end
end