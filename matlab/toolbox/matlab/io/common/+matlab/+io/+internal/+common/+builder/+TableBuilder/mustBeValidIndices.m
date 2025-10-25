function mustBeValidIndices(SelectedVariableIndices)
%mustBeValidIndices   Property/arguments validation for SelectedVariableIndices.
%

%   Copyright 2022 The MathWorks, Inc.

    mustBeFinite(SelectedVariableIndices);
    mustBeInteger(SelectedVariableIndices);
    mustBePositive(SelectedVariableIndices);
end
