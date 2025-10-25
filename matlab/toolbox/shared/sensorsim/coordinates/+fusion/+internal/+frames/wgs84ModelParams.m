%This function is for internal use only. It may be removed in the future.

%WGS84MODELPARAMS World Geodetic System 1984 Model parameters
%   [a, f, mu, w] = fusion.internal.frames.wgs84ModelParams() returns the
%   following parameters of the World Geodetic System 1984 Model:
%       a  - semi-major axis (m)
%       f  - flattening
%       mu - gravitational constant (m^3/s^2)
%       w  - rotation rate (rad/s)

%   Copyright 2017-2020 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function [a, f, mu, w] = wgs84ModelParams(varargin)
    dataType = 'double';
    if numel(varargin) == 1
        dataType = varargin{1};
    end

    % Semi-major axis (m)
    a =  cast(6378137, dataType);

    % Flattening
    f  = cast(1/298.257223563, dataType);

    % Gravitational constant (m^3/s^2)
    mu = cast(3.986005e14, dataType);

    % Rotation rate (rad/s)
    w = cast(7.2921151467e-5, dataType);
end
