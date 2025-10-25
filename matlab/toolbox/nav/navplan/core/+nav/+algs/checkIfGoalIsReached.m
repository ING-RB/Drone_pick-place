function isReached = checkIfGoalIsReached(planner, newState, goalState)
%CHECKIFGOALISREACHED Default GoalReachedFcn for plannerRRT

%   Copyright 2019-2022 The MathWorks, Inc.

%#codegen

isReached = false;
threshold = 0.5;
if planner.StateSpace.distance(newState, goalState) < threshold
    isReached = true;
end

end

