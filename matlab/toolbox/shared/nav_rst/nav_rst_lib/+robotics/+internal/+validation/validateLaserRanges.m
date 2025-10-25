function validRanges = validateLaserRanges(inRanges, fcnName, argName)
%This function is for internal use only. It may be removed in the future.

%VALIDATELASERRANGES Validate ranges for laser scan
%   NaN and Inf values are allowed in validation (for some sensors they indicate invalid
%   range readings). The calling method has to decide on what to
%   do with NaN and Inf ranges.
%   VALIDRANGES is guaranteed to be a column vector of valid angles.

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen

if isempty(inRanges)
    % Allow empty ranges as valid
    validateattributes(inRanges, {'single', 'double'}, {}, fcnName, argName);
else
    validateattributes(inRanges, {'single', 'double'}, {'nonempty', 'vector', 'real', 'nonnegative'}, fcnName, argName);
end

% Make sure that the output is always a column vector
validRanges = inRanges(:);

end

