function [interpID, extrapID] = validateInterpExtrapMethod(varargin)
% Validate interp and extrap methods.
% First input, if present, is interpolation method given as user input.
% Second input, if present, is extrapolation method given as user input.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
coder.internal.prefer_const(varargin);
narginchk(0,2);

if nargin == 0
    % Default interp and extrap, both are 'liner'
    interpID = coder.internal.interpolate.interpMethodsEnum.LINEAR;
    extrapID = interpID;
elseif nargin == 1
    % User input interp, default extrap
    [interpID, isnatural] = validateInterpMethod(varargin{1});
    if isnatural
        % Extrap defaults to 'linear' in case of 'natural' interpolation
        % method.
        extrapID = coder.internal.interpolate.interpMethodsEnum.LINEAR;
    else
        extrapID = interpID;
    end
elseif nargin == 2
    % Both methods are user inputs.
    interpID = validateInterpMethod(varargin{1});
    extrapID = validateExtrapMethod(varargin{2});
end

%--------------------------------------------------------------------------

function extrapID = validateExtrapMethod(eMethod)
% Validate extrapolation method and return enum
coder.inline('always');
coder.internal.prefer_const(eMethod);
coder.internal.errorIf(strcmp(eMethod, 'natural'), ...
                       'MATLAB:mathcgeo_catalog:NoNaturalExtrapErrId'); % natural method is invalid for extrapolation
islinear = strcmp(eMethod, 'linear');
isnearest = strcmp(eMethod, 'nearest');
isboundary = strcmp(eMethod, 'boundary');
isnone = strcmp(eMethod, 'none');
b = islinear || isnearest || isboundary || isnone;
coder.internal.assert(b, 'MATLAB:mathcgeo_catalog:BadExtrapTypeErrId');
extrapID = coder.internal.interpolate.StringToMethodID(eMethod);

%--------------------------------------------------------------------------

function [interpID, isnatural] = validateInterpMethod(iMethod)
% Validate interpolation method and return enum
coder.inline('always');
coder.internal.prefer_const(iMethod);
islinear = strcmp(iMethod, 'linear');
isnearest = strcmp(iMethod, 'nearest');
isnatural = strcmp(iMethod, 'natural');
b = islinear || isnearest || isnatural;
coder.internal.assert(b, 'MATLAB:mathcgeo_catalog:BadInterpTypeErrId');
interpID = coder.internal.interpolate.StringToMethodID(iMethod);
