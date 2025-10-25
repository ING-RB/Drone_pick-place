function units = powerUnitsHelper(~,varDimRight,~)
% POWERUNITSHELPER Helper to validate and merge VariableUnits for .^.

%   Copyright 2022 The MathWorks, Inc.

% VALIDATION: The RHS unit must always be empty ('').
%
% OUTPUT    : {}. 

if varDimRight.hasUnits && any(varDimRight.hasNonEmptyUnits)
    error(message('MATLAB:table:math:IncompatibleUnits'));
end
units = {};