%This function is for internal use only. It may be removed in the future.

%LLA2ECEF Geodetic LLA to geocentric ECEF
%   ecefPos = lla2ecef(llaPos) converts the M-by-3 array of geodetic LLA
%   coordinates, llaPos, to an M-by-3 array of geocentric ECEF
%   coordinates, ecefPos. llaPos is in [degrees degrees meters]. ecefPos is
%   in meters. The ellipsoid planet is WGS84.
% 
%   ecefPos = lla2ecef(...,ellipsoid) defines the ellipsoid planet in
%   vector form as [semi-major axis, eccentricity]. The default is the
%   WGS84 ellipsoid.
%
%   % Example:
%   % Convert LLA coordinates at Natick, MA to ECEF coordinates.
%
%   llaPos = [42 -71 53];
%   ecefPos = fusion.internal.frames.lla2ecef(llaPos);

%   Copyright 2017-2023 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function ecefPos = lla2ecef(llaPos,varargin)

    [a, f] = fusion.internal.frames.parsePlanetModel(class(llaPos),varargin{:});

    phi = llaPos(:,1);
    lambda = llaPos(:,2);
    h = llaPos(:,3);

    [rho, z] = map.geodesy.internal.geodetic2cylindrical(phi, h, a, f, true);

    x = rho .* cosd(lambda);
    y = rho .* sind(lambda);

    ecefPos = [x y z];
end
