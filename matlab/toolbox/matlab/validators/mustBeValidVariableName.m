function mustBeValidVariableName(varname)
%MUSTBEVALIDVARIABLENAME Validate that value is a valid variable name
%   MUSTBEVALIDVARIABLENAME(NAME) throws an error if NAME is not a valid MATLAB variable
%   identifier.
%
%   MATLAB calls isvarname to determine if NAME is a valid variable identifier.
%   NAME can be a string array, a character vector, or a cell array of
%   character vectors.
%
%   See also ISVARNAME.

%   Copyright 2020-2024 The MathWorks, Inc.

if ~matlab.internal.validation.util.isNontrivialText(varname)
    throwAsCaller(MException("MATLAB:validators:mustBeNonzeroLengthText", ...
        message("MATLAB:validators:nonzeroLengthText")));
end

varname = string(varname);

tf = arrayfun(@(aname)isvarname(aname),varname);

if ~all(tf, 'all')
    throwAsCaller(matlab.internal.validation.util.createExceptionForMissingItems(unique(varname(~tf)), ...
        'MATLAB:validators:mustBeValidVariableName'));
end

% LocalWords:  validators
