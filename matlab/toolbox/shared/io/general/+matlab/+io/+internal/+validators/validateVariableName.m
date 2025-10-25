
function tf = validateVariableName(variableName, checkValidMATLABIdentifier)
% VALIDATEVARIABLENAME verifies if the first input argument can be a valid
% table variable name. Will also do an additional check to ensure that the
% first input argument is a valid MATLAB identifier if the second argument
% is provided and set to true.
% Note that this does not check for possible duplicate variable names in
% the table. That is expected to be handled later when actually reading the
% variables in the table.
% Additionally, this does not check for reserved table variable names,
% which are also expected to be normalized later when reading.

% Copyright 2019 The MathWorks, Inc.

% Validate for the new table behavior by default.
    if nargin < 2
        checkValidMATLABIdentifier = false;
    end

    % Return false if a string scalar or a char vector isn't passed in.
    hasStringLikeType = isStringScalar(variableName) || ischar(variableName);

    % Ensure that the variable name is nonempty and is smaller than
    % namelengthmax
    hasCorrectSize = ~isempty(variableName) && (numel(variableName) <= namelengthmax);

    % Check if this is a valid MATLAB identifier, only if necessary.
    if checkValidMATLABIdentifier
        hasValidIdentifiers = isvarname(variableName);
    else
        hasValidIdentifiers = true;
    end

    tf = hasStringLikeType && hasCorrectSize && hasValidIdentifiers;

end
