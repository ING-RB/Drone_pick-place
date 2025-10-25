%This function is for internal use only. It may be removed in the future.

%ECEF2ENU Geocentric ECEF to local Cartesian ENU
%   enuPos = ecef2enu(ecefPos, lla0) converts the M-by-3 array of
%   geocentric ECEF coordinates, ecefPos, to an M-by-3 array of local
%   Cartesian ENU coordinates, enuPos, given a local coordinate system
%   defined by the geodetic coordinates of its origin, lla0. ecefPos is in
%   meters. enuPos is in meters. lla0 is in [degrees degrees meters]. The
%   ellipsoid planet is WGS84.
%
%   enuPos = ecef2enu(...,ellipsoid) defines the ellipsoid planet in
%   vector form as [semi-major axis, eccentricity]. The default is the WGS84
%   ellipsoid.
%
%
%   % Example:
%   % Convert local ENU position to ECEF coordinates based on an origin
%   % near Natick, MA.
%
%   lla0 = [42 -71 53];
%   ecefPos = [1545485 -4488413 4245639];
%   enuPos = fusion.internal.frames.ecef2enu(ecefPos, lla0);

%   Copyright 2017-2023 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function enuPos = ecef2enu(ecefPos, lla0, varargin)

    phi = lla0(:,1);
    lambda = lla0(:,2);

    cosphi = cosd(phi);
    sinphi = sind(phi);
    coslambda = cosd(lambda);
    sinlambda = sind(lambda);

    ecef0 = fusion.internal.frames.lla2ecef(lla0,varargin{:});

    % Computing the difference in the ECEF frame for now,
    % oblateSpheroid/ecefOffset has a different algorithm that minimizes
    % numerical round off.
    ecefPosWithENUOrigin = ecefPos - ecef0;
    x = ecefPosWithENUOrigin(:,1);
    y = ecefPosWithENUOrigin(:,2);
    z = ecefPosWithENUOrigin(:,3);

    % To rotate ECEF to ENU frame, use the transpose of the rotation matrix that
    % rotates the ENU to ECEF frame (origin is the reference LLA coordinates).
    % rotENU2ECEF = Rz(-(pi/2 + lambda)) * Ry(0) * Rx(-(pi/2 - phi))
    % rotENU2ECEF = [-sinlambda -coslambda.*sinphi coslambda.*cosphi
    %                 coslambda -sinlambda.*sinphi sinlambda.*cosphi
    %                     0            cosphi            sinphi     ];
    % rotECEF2ENU = rotENU2ECEF.';
    % rotECEF2ENU = [     -sinlambda          coslambda      0
    %                -coslambda.*sinphi -sinlambda.*sinphi cosphi
    %                 coslambda.*cosphi  sinlambda.*cosphi sinphi];

    uEast = -sinlambda .* x + coslambda .* y;
    tmp = coslambda .* x + sinlambda .* y;
    vNorth = -sinphi .* tmp + cosphi .* z;
    wUp    =  cosphi .* tmp + sinphi .* z;

    enuPos = [uEast vNorth wUp];
end
