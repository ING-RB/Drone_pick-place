function units = relationalUnitsHelper(varDimLeft,varDimRight,~)
% RELATIONALUNITSHELPER Helper to validate and merge VariableUnits for relational ops.

%   Copyright 2022 The MathWorks, Inc.

% VALIDATION: For each variable, both inputs must either have the same units or
%             one of the inputs must have empty unit ('').
%
% OUTPUT    : {} 


if varDimLeft.hasUnits && varDimRight.hasUnits
    unitsLeft = varDimLeft.units;
    unitsRight = varDimRight.units;
    hasUnitsLeft = varDimLeft.hasNonEmptyUnits;
    hasUnitsRight = varDimRight.hasNonEmptyUnits;
    hasUnitsBoth = hasUnitsLeft & hasUnitsRight;
    if ~isequal(unitsLeft(hasUnitsBoth),unitsRight(hasUnitsBoth))
        % If A and B have different non-empty units then it is an error.
        error(message('MATLAB:table:math:IncompatibleUnits'));
    end
end
units = {};