function cost = analyticalExpansionCost(rsPathSegObj, forwardCost, reverseCost)
%analyticalExpansionCost Returns weighted sum of the motion lengths
% of reverse and forward paths in the Reeds-Shepp path object

%   Copyright 2023 The MathWorks, Inc.

%#codegen

narginchk(1,3);

if nargin == 1
    %Default forward and reverse cost of plannerHybridAStar
    forwardCost = 1;
    reverseCost = 3;
elseif nargin == 2
    %Default reverse cost of plannerHybridAStar
    reverseCost = 3;
end

forwardPathIdx = rsPathSegObj.MotionDirections == 1;
cost = sum(rsPathSegObj.MotionLengths(forwardPathIdx).*forwardCost);
cost = cost + sum(rsPathSegObj.MotionLengths(~forwardPathIdx).*reverseCost);
end