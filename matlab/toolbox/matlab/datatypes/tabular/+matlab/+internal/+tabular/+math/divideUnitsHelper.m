function units = divideUnitsHelper(varDimLeft,varDimRight,fun)
% DIVIDEUNITSHELPER Helper to validate and merge VariableUnits for ./ and .\.

%   Copyright 2022 The MathWorks, Inc.

% VALIDATION: No validation required.
%
% OUTPUT    : If the unit is defined for the LHS but is empty for the RHS then
%             select the unit from LHS. Otherwise use empty unit ('').

if ~varDimLeft.hasUnits
    units = {};
    warnVars = [];
elseif ~varDimRight.hasUnits
    units = varDimLeft.units;
    warnVars = varDimLeft.hasNonEmptyUnits;
else % both have units
    units = varDimLeft.units;
    hasUnitsLeft = varDimLeft.hasNonEmptyUnits;
    hasUnitsRight = varDimRight.hasNonEmptyUnits;
    units(hasUnitsRight) = {''};
    warnVars = hasUnitsLeft & ~hasUnitsRight;
end

if any(warnVars)
    warning(message("MATLAB:table:math:AssumeUnitless",func2str(fun)));
end