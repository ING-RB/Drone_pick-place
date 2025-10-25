function [phi, h] = cylindrical2geodetic(rho, z, a, f, inDegrees)
%cylindrical2geodetic Geocentric cylindrical to geodetic coordinates
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [phi,h] = map.geodesy.internal.cylindrical2geodetic(rho,z,a,f,inDegrees)
%   returns geodetic coordinates corresponding to radial distance rho and
%   signed distance from the equator z in a spheroid-centric (ECEF)
%   cylindrical coordinate system.
%
%   Input Arguments
%   ----------------
%   rho -- Radial distance from polar axis of one or more points, specified
%      as a scalar value, vector, matrix, or N-D array. Values must be in
%      units that match the length unit of the semimajor axis.
%
%      Data types: single | double
%
%   z -- Signed distance from equatorial plane of one or more points from
%      the equatorial plane, specified as a scalar value, vector, matrix,
%      or N-D array (equivalent to the z-coordinate the spheroid-centric
%      ECEF Cartesian system). Values must be in units that match the
%      length unit of the semimajor axis.
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
%   ---------------
%   phi -- Geodetic latitude of one or more points, returned as a scalar
%      value, matrix, or N-D array. Units are determined by the inDegrees
%      flag. When in degrees, they lie in the closed interval [-90 90].
%
%   h -- Ellipsoidal height of one or more points, specified as a scalar
%      value, vector, matrix, or N-D array. Units are determined by the
%      length unit of the semimajor axis.
%
%   Notes
%   -----
%   This function follows standard elementwise behavior with respect to
%   inputs rho and z, including scalar expansion.
%
%   Longitude in a 3-D spheroid-centric cylindrical system is the same as
%   in the corresponding geodetic system, and hence is not needed as either
%   an input or an output. Another perspective is that this function
%   performs a 3-D spheroid-centric ECEF to geodetic transformation in the
%   plane of a meridian.
%
%   See also map.geodesy.internal.geodetic2cylindrical

% Copyright 2012-2020 The MathWorks, Inc.

%#codegen

% Spheroid properties
b = (1 - f) * a;       % Semiminor axis
e2 = f * (2 - f);      % Square of (first) eccentricity
ae2 = a * e2;
bep2 = b * e2 / (1 - e2);   % b * (square of second eccentricity)

% Starting value for parametric latitude (beta), following Bowring 1985
r = hypot(rho, z);
u = a * rho;                    % vs. u = b * rho (Bowring 1976)
v = b * z .* (1 + bep2 ./ r);   % vs. v = a * z   (Bowring 1976)
cosbeta = sign(u) ./ hypot(1, v./u);
sinbeta = sign(v) ./ hypot(1, u./v);

% Fixed-point iteration with Bowring's formula
% (typically converges within three iterations or less)
count = 0;
iterate = true;
while iterate && count < 5
    cosprev = cosbeta;
    sinprev = sinbeta;
    u = rho - ae2  * cosbeta.^3;
    v = z   + bep2 * sinbeta.^3;
    au = a * u;
    bv = b * v;
    cosbeta = sign(au) ./ hypot(1, bv ./ au);
    sinbeta = sign(bv) ./ hypot(1, au ./ bv);
    iterate = any(hypot(cosbeta - cosprev, sinbeta - sinprev) > eps(pi/2), 'all');
    count = count + 1;
end

% Final latitude in degrees or radians
if inDegrees
    phi = atan2d(v,u);
    cosphi = cosd(phi);
    sinphi = sind(phi);
else
    phi = atan2(v,u);
    cosphi = cos(phi);
    sinphi = sin(phi);
end

% Ellipsoidal height from final value for geodetic latitude
N = a ./ sqrt(1 - e2 * sinphi.^2);
h = rho .* cosphi + (z + e2 * N .* sinphi) .* sinphi - N;

% Implementation Notes from Rob Comer
% --------------------------------------------------
% This implementation follows Wolf and DeWitt, with a few exceptions
% that improve performance and ensure good numerical behavior:
%
% 1) The starting value for parametric latitude uses the expression
%    from Bowring's 1985 paper, in place of the one from his 1976 paper.
%
% 2) I initialize and iterate over the cosine and sine of the parametric
%    latitude, beta, rather than using an arc tangent call to compute beta
%    explicitly and then turning around and calling cos (or cosd) and sin
%    (or sind) to feed into the expressions involving the cubes of the
%    cosine and sine. I also avoid explicit computation of geodetic
%    latitude (phi) during the iteration, further eliminating trig and
%    inverse trig function calls.
%
%    The computation:
%
%       cosbeta = sign(u) ./ hypot(1, v./u)
%       sinbeta = sign(v) ./ hypot(1, u./v)
%
%    is equivalent to:
%
%       beta = atan2(v,u)
%       cosbeta = cos(u)
%       sinbata = sin(u)
%
%    but is much faster. It's also equivalent to:
%
%       cosbeta = u ./ hypot(u,v)
%       sinbeta = v ./ hypot(u,v)
%
%    but these more obvious formulas don't handle edge cases with infinite
%    input as effectively.
%
% 3) Rather than terminate the fixed point iteration when beta ceases
%    to change, I use an equivalent approach that avoids the need for arc
%    tangent calls: look for the change in the distance between the points
%    (cos(beta), sin(beta)) and (cos(previous beta), sin(previous beta) to
%    become vanishingly small. These points fall on the unit circle. The
%    change in beta, in radians, is the distance between these points as
%    measured along the arc of the circle. For a small change in angle,
%    this arc length is very closely approximated by the straight line
%    distance (the chord length, that is) between the points.
%
% 4) I use ATAN2 (or ATAN2D) instead of ATAN when computing phi from its
%    cosine and sine, ensuring stability even for points at very high
%    latitudes. This, in fact, is the only trig call in the entire
%    function.
%
% 5) Finally, I avoid dividing by cos(phi) -- also problematic at high
%    latitudes -- in the calculation of h, the height above the ellipsoid.
%    Wolf and Dewitt give
%
%                   h = sqrt(X^2 + Y^2)/cos(phi) - N,
%
%    or
%
%                   h = rho/cos(phi) - N,
%
%    The trick is to notice an alternate formula that involves division
%    by sin(phi) instead of cos(phi), then take a linear combination of the
%    two formulas weighted by cos(phi)^2 and sin(phi)^2, respectively. This
%    eliminates all divisions and, because of the identity cos(phi)^2 +
%    sin(phi)^2 = 1 and the fact that both formulas give the same h, the
%    linear combination is also equal to h.
%
%    To obtain the alternate formula, we simply rearrange
%
%              Z = [N(1 - e^2) + h]sin(phi)
%    into
%              h = Z/sin(phi) - N(1 - e^2).
%
%    The linear combination is thus
%
%        h = (rho/cos(phi) - N) cos^2(phi)
%            + (Z/sin(phi) - N(1 - e^2))sin^2(phi)
%
%    which simplifies to
%
%        h = rho cos(phi) + (z + e2 N sin(phi)) sin(phi) - N;
%          = rho cos(phi) + Z sin(phi) - N(1 - e^2sin^2(phi))
%          = rho cos(phi) + Z sin(phi) - a sqrt(1 - e^2sin^2(phi)).
%
%    Of these three equivalent formulas, the first one seems to most
%    frequently result in a perfect round trip between geodetic2cylindrical
%    and cylindrical2geodetic.
%
%    It's not hard to verify that along the Z-axis h = Z - b and in the
%    equatorial plane h = rho - a.
%
%    The formulas for h turn out to be equivalent to the one that Bowring
%    (1985) derived by via a geometric argument:
%
%        h = rho cos(phi) + Z sin(phi) - a.^2 / N.
%
% References
%
%   Wolf, Paul R. and Bon A. Dewitt, Elements of Photogrammetry with
%   Applications in GIS, 3rd Edition, McGraw-Hill, 2000, pp. 571-573
%   (presents the iterative approach from Bowring's 1976 paper).
%
%   Bowring, B.R. (1985). The Accuracy of Geodetic Latitude and Height
%   Equations, Survey Review, 28(218):202-206 (suggests a better starting
%   value for parametric latitude and a numerically stable formula for
%   height above the ellipsoid).
