function validAngles = validateLaserAngles(inAngles, fcnName, argName, allowNonFiniteAngles)
%This function is for internal use only. It may be removed in the future.

%VALIDATELASERANGLES Validate angles for laser scan
%   VALIDANGLES is guaranteed to be a column vector of valid angles.

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen

if nargin <= 3
    % If not user-specified, disallow non-finite angles
    allowNonFiniteAngles = false;
end

if isempty(inAngles)
    validateattributes(inAngles, {'single', 'double'}, {}, fcnName, argName);
else
    if ~allowNonFiniteAngles
        validateattributes(inAngles, {'single', 'double'}, {'vector', 'real', 'nonnan', 'finite'}, fcnName, argName);
    else
        validateattributes(inAngles, {'single', 'double'}, {'vector', 'real'}, fcnName, argName);
    end
end 

% Make sure that the output is always a column vector
validAngles = inAngles(:);

end

