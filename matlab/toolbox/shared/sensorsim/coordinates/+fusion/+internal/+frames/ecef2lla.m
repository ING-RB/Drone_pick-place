%This function is for internal use only. It may be removed in the future.

%ECEF2LLA Geocentric ECEF to geodetic LLA
%   llaPos = ecef2lla(ecefPos) converts the M-by-3 array of geocentric ECEF
%   coordinates, ecefPos, to an M-by-3 array of geodetic LLA coordinates.
%   ecefPos is in meters. llaPos is in [degrees degrees meters]. The
%   ellipsoid planet is WGS84.
%
%   llaPos = ecef2lla(...,ellipsoid) defines the ellipsoid planet in vector
%   form as [semi-major axis, eccentricity]. The default is the WGS84
%   ellipsoid.
%
%   % Example:
%   % Convert geocentric ECEF position at Natick, MA to LLA coordinates.
%
%   ecefPos = [1545485 -4488413 4245639];
%   llaPos = fusion.internal.frames.ecef2lla(ecefPos);

%   Copyright 2017-2023 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function llaPos = ecef2lla(ecefPos,varargin)

    [a, f] = fusion.internal.frames.parsePlanetModel(class(ecefPos),varargin{:});

    % atan2d requires its inputs to be strictly real in codegen
    ecefPos = real(ecefPos);

    x = ecefPos(:,1);
    y = ecefPos(:,2);
    z = ecefPos(:,3);

    rho = hypot(x, y);

    lon = atan2d(y, x);

    [lat, alt] = map.geodesy.internal.cylindrical2geodetic(rho, z, a, f, true);

    llaPos = [lat lon alt];
end
