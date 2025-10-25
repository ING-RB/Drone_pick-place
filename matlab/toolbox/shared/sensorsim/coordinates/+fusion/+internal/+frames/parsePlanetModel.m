%This function is for internal use only. It may be removed in the future.

%PARSEPLANETMODEL Planet model parsing for optional input arguments
%   [a, f, mu, w] = fusion.internal.frames.parsePlanetModel() returns the
%   World Geodetic System 1984 (WGS-84) Model:
%       a  - semi-major axis (m)
%       f  - flattening
%       mu - gravitational constant (m^3/s^2)
%       w  - rotation rate (rad/s)
%
%   [...] = parsePlanetModel(DT) returns the WGS-84 model using the
%   datatype DT for the model parameters.
%
%   [...] = parsePlanetModel(...,ELLIP) returns the model parameters using
%   the planet model defined by the ellipsoid vector ELLIP whose elements
%   are defined as [semi-major axis, eccentricity] to compute the
%   semi-major axis and flattening parameters. The gravitational constant
%   and rotation rate parameters from the WGS-84 model are unchanged. If
%   the datatype, DT, is omitted, then the datatype of the returned model
%   parameters is taken from the ellipsoid vector.

%   Copyright 2023 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen
function [a, f, mu, w] = parsePlanetModel(varargin)
if nargin==0 || ...
        nargin==1 && hasDataType(varargin{1})
    % Pass-through to use the WGS-84 model parameters
    [a, f, mu, w] = fusion.internal.frames.wgs84ModelParams(varargin{:});
else
    % Use the ellipsoid vector to compute semi-major axis and flattening

    if hasDataType(varargin{1})
        dataType = varargin{1};
        ellip = varargin{2};
    else
        ellip = varargin{1};
        dataType = class(ellip);
    end
    a = cast(ellip(1),dataType);
    e2 = ellip(2)^2;
    f = cast(1-sqrt(1-e2),dataType);

    if nargout>2
        % use the WGS-84 model for the gravitational constant and rotation
        % rate parameters when requested.
        [~,~,mu,w] = fusion.internal.frames.wgs84ModelParams(dataType);
    end
end
end

function flag = hasDataType(arg)
flag = ischar(arg) || isstring(arg);
end
