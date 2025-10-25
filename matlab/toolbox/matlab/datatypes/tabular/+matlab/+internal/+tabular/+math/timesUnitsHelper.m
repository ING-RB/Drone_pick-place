function units = timesUnitsHelper(varDimLeft,varDimRight,fun)
% TIMESUNITSHELPER Helper to validate and merge VariableUnits for .*.

%   Copyright 2022 The MathWorks, Inc.

% VALIDATION: No validation required.
%
% OUTPUT    : If only one input has a non-empty unit then select that. Otherwise
%             use empty unit (''). 

if ~varDimLeft.hasUnits
    units = varDimRight.units;
    warnVars = varDimRight.hasNonEmptyUnits;
elseif ~varDimRight.hasUnits
    units = varDimLeft.units;
    warnVars = varDimLeft.hasNonEmptyUnits;
else % both have units
    units = repmat({''},1,varDimLeft.length);
    unitsA = varDimLeft.units;
    unitsB = varDimRight.units;
    hasUnitsA = varDimLeft.hasNonEmptyUnits;
    hasUnitsB = varDimRight.hasNonEmptyUnits;
    units(hasUnitsA & ~hasUnitsB) = unitsA(hasUnitsA & ~hasUnitsB);
    units(~hasUnitsA & hasUnitsB) = unitsB(~hasUnitsA & hasUnitsB);
    warnVars = xor(hasUnitsA,hasUnitsB);
end

if any(warnVars)
    % For any variable, if the unit is non-empty for one input and empty for the
    % other then for these operations we assume that the empty/undefined unit to
    % mean unitless. Warn the user about this assumption.
    warning(message("MATLAB:table:math:AssumeUnitless",func2str(fun)));
end