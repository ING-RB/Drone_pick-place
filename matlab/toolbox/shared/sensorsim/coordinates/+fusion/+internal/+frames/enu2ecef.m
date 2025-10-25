%This function is for internal use only. It may be removed in the future.

%ENU2ECEF Local Cartesian ENU to geocentric ECEF
%   ecefPos = enu2ecef(enuPos, lla0) converts the M-by-3 array of local
%   Cartesian ENU coordinates, enuPos, to an M-by-3 array of geocentric
%   ECEF coordinates, ecefPos, given a local coordinate system defined by
%   the geodetic coordinates of its origin, lla0. enuPos is in meters.
%   ecefPos is in meters. lla0 is in [degrees degrees meters]. The
%   ellipsoid planet is WGS84.
%
%   ecefPos = enu2ecef(...,ellipsoid) defines the ellipsoid planet in
%   vector form as [semi-major axis, eccentricity]. The default is the
%   WGS84 ellipsoid.
%
%   % Example:
%   % Convert local ENU position to ECEF coordinates based on an origin
%   % near Natick, MA.
%
%   lla0 = [42 -71 53];
%   enuPos = [0 0 0];
%   ecefPos = fusion.internal.frames.enu2ecef(enuPos, lla0);

%   Copyright 2017-2023 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function ecefPos = enu2ecef(enuPos, lla0, varargin)

    uEast  = enuPos(:,1);
    vNorth = enuPos(:,2);
    wUp    = enuPos(:,3);

    phi = lla0(:,1);
    lambda = lla0(:,2);

    cosphi = cosd(phi);
    sinphi = sind(phi);
    coslambda = cosd(lambda);
    sinlambda = sind(lambda);

    ecef0 = fusion.internal.frames.lla2ecef(lla0, varargin{:});
    x0 = ecef0(:,1);
    y0 = ecef0(:,2);
    z0 = ecef0(:,3);

    % Rotate ENU to ECEF frame (origin is the reference LLA coordinates)
    % rotENU2ECEF = Rz(-(pi/2 + lambda)) * Ry(0) * Rx(-(pi/2 - phi))
    % rotENU2ECEF = [-sinlambda -coslambda.*sinphi coslambda.*cosphi
    %                 coslambda -sinlambda.*sinphi sinlambda.*cosphi
    %                     0            cosphi            sinphi     ];
    tmp = cosphi .* wUp - sinphi .* vNorth;
    dx = coslambda .* tmp - sinlambda .* uEast;
    dy = sinlambda .* tmp + coslambda .* uEast;
    dz = sinphi .* wUp + cosphi .* vNorth;

    % Translate values so that origin aligns with Earth's origin.
    x = x0 + dx;
    y = y0 + dy;
    z = z0 + dz;

    ecefPos = [x y z];
end
