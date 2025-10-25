function mustBeUnderlyingType(obj, typenames)
%mustBeUnderlyingType  Validate value has one of the specified underlying types.
%
%   mustBeUnderlyingType(VALUE, Typenames) issues an error if VALUE does
%   not have underlying type equal to one of the specified Typenames.
%   TypeNames can be a string array, a character vector, or a cell array of
%   character vectors.
%
%   Examples:
%   x = zeros(2,2,"single");
%   mustBeUnderlyingType(x,"single")   % OK - underlyingType is single
%
%   x = gpuArray(eye(3,"uint8"));
%   mustBeUnderlyingType(x,["single", "double"])   % Error - underlyingType is uint8
%
%   x = dlarray(gpuArray(rand(3)));
%   mustBeUnderlyingType(x, ["gpuArray", "dlarray"]) % Error - underlyingType is double
%
%   x = {1,2,3};
%   mustBeUnderlyingType(x,"double")   % Error - underlyingType is cell
%
%   x = table([1;2],[3;4]);
%   mustBeUnderlyingType(x,"table")    % OK - underlyingType is table
%
%   See also: isUnderlyingType, mustBeA.

%   Copyright 2020-2024 The MathWorks, Inc.

if ~iIsText(typenames)
    throwAsCaller(matlab.internal.validation.util.createValidatorException("MATLAB:validators:mustBeNonzeroLengthText", ...
        getString(message("MATLAB:validatorUsage:nonTextSecondInput", "mustBeUnderlyingType"))));
end

% Convert to strings and validate strings
typenames = string(typenames);
for k = 1:numel(typenames)
    if ismissing(typenames(k)) || strlength(typenames(k)) == 0
        throwAsCaller(matlab.internal.validation.util.createValidatorException("MATLAB:validators:mustBeNonzeroLengthText", ...
            getString(message("MATLAB:validatorUsage:notTextOrTrivialTextSecondInput", "mustBeUnderlyingType"))));
    end
end

% isUnderlyingType validation
for k = 1:numel(typenames)
    if isUnderlyingType(obj, typenames(k)) % PKG_ADOPT
        return
    end
end

throwAsCaller(matlab.internal.validation.util.createValidatorException("MATLAB:validators:mustBeUnderlyingType", strjoin(typenames, ', ')));
end


function tf = iIsText(arg)
% String array, character vector or cell array of character vectors with
% non-zero length text.
tf = (ischar(arg) && isrow(arg)) || isstring(arg) || iscellstr(arg);
end
