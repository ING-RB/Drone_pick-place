function units = plusUnitsHelper(varDimLeft,varDimRight,fun)
% PLUSUNITSHELPER Helper to validate and merge VariableUnits for +, -, rem and mod.

%   Copyright 2022 The MathWorks, Inc.

% VALIDATION: For each variable, both inputs must either have the same units or
%             one of the inputs must have empty unit ('').
%
% OUTPUT    : Select the first non-empty unit for each variable. 

if ~varDimLeft.hasUnits
    units = varDimRight.units;
    warnVars = varDimRight.hasNonEmptyUnits;
elseif ~varDimRight.hasUnits
    units = varDimLeft.units;
    warnVars = varDimLeft.hasNonEmptyUnits;
else % both have units
    unitsLeft = varDimLeft.units;
    unitsRight = varDimRight.units;
    hasUnitsLeft = varDimLeft.hasNonEmptyUnits;
    hasUnitsRight = varDimRight.hasNonEmptyUnits;
    hasUnitsBoth = hasUnitsLeft & hasUnitsRight;
    if ~isequal(unitsLeft(hasUnitsBoth),unitsRight(hasUnitsBoth))
        error(message('MATLAB:table:math:IncompatibleUnits'));
    end
    units = unitsLeft;
    units(~hasUnitsLeft) = unitsRight(~hasUnitsLeft);
    warnVars = xor(hasUnitsLeft,hasUnitsRight);
end

if any(warnVars)
    % For any variable, if the unit is non-empty for one input and empty for the
    % other then for these operations we assume that the empty/undefined unit is
    % the same as the non-empty one. Warn the user about this assumption.
    warning(message("MATLAB:table:math:AssumeSameUnits",func2str(fun)));
end