function [rho, z] = geodetic2cylindrical(phi, h, a, f, inDegrees)
% geodetic2cylindrical Geodetic to geocentric cylindrical coordinates
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [rho,z] = map.geodesy.internal.geodetic2cylindrical(phi,h,a,f,inDegrees)
%   returns coordinates in a spheroid-centric (ECEF) cylindrical coordinate
%   system corresponding to geodetic latitude phi and ellipsoidal height h.
%
%   Input Arguments
%   ---------------
%   phi -- Geodetic latitude of one or more points, specified as a scalar
%      value, matrix, or N-D array. Values must be in units consistent with
%      the inDegrees flag.
%
%      Data types: single | double
%
%   h -- Ellipsoidal height of one or more points, specified as a scalar
%      value, vector, matrix, or N-D array. Values must be in units that
%      match the length unit of the semimajor axis.
%
%      Data types: single | double
%
%   a -- Semimajor axis of reference spheroid, specified as a scalar number.
%
%      Data type: double
%
%   f -- Flattening of reference spheroid, specified as a scalar number.
%
%      Data type: double
%
%   inDegrees -- Unit of angle flag, specified as a scalar logical. The
%      value true indicates that geodetic latitude phi is in degrees;
%      false indicates that phi is in radians.
%
%      Data type: logical
%
%   Output Arguments
%   ----------------
%   rho -- Radial distance of points from the polar axis, returned as a
%      scalar value, vector, matrix, or N-D array. Units are determined by
%      the length unit of the semimajor axis.
%
%   z -- Signed distance from the equatorial plane, returned as a scalar
%      value, vector, matrix, or N-D array (equivalent to the z-coordinate
%      the spheroid-centric ECEF system). Units are determined by the
%      length unit of the semimajor axis.
%
%   Note
%   ----
%   This function follows standard elementwise behavior with respect to
%   inputs phi and h, including scalar expansion.
%
%   Longitude in a 3-D spheroid-centric cylindrical system is the same as
%   in the corresponding geodetic system, and hence is not needed as either
%   an input or an output. Another perspective is that this function
%   performs a 3-D geodetic to spheroid-centric ECEF transformation in the
%   plane of a meridian.
%
%   See also map.geodesy.internal.cylindrical2geodetic

% Copyright 2012-2019 The MathWorks, Inc.

%#codegen

if inDegrees
    sinphi = sind(phi);
    cosphi = cosd(phi);
else
    sinphi = sin(phi);
    cosphi = cos(phi);
end

e2 = f * (2 - f);
N  = a ./ sqrt(1 - e2 * sinphi.^2);
rho = (N + h) .* cosphi;
z = (N*(1 - e2) + h) .* sinphi;
