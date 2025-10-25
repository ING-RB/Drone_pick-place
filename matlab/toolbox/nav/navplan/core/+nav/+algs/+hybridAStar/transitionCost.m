function gCost = transitionCost(motionSegment)
%   Inputs
%     motionSegment is a struct with the following fields:
%       Curvature              - N-element vector of curvatures
%       Direction              - N-element vector of direction signs
%       StartState             - 1-by-3 pose [x y th]
%       MotionPrimitiveLength  - scalar motion primitive length
%       ForwardCost            - scalar forward cost
%       ReverseCost            - scalar reverse cost
%       DirectionSwitchingCost - N-element vector for direction switching
%                                costs
%   
%   Outputs
%     gCost - N-element vector of G cost 

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Create cost vector based on directions, forward, and reverse costs.
curvature = motionSegment.Curvature;
cost = repmat(motionSegment.ForwardCost, numel(curvature), 1);
cost(motionSegment.Direction == -1) = motionSegment.ReverseCost;

gCost = cost.*(motionSegment.MotionPrimitiveLength + abs(curvature))...
    +motionSegment.DirectionSwitchingCost;
end
