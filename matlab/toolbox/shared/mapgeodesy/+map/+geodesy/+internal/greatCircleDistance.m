 function [S, az] = greatCircleDistance(lat1, lon1, lat2, lon2, radius)
%greatCircleDistance Great-circle distance and azimuth on sphere
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [S,az] = map.geodesy.internal.greatCircleDistance(lat1,lon1,lat2,lon2)
%   returns the arc length, S, and azimuth angle, az, of a great circle on
%   a sphere connecting a point at (lat1,lon1) to a point at (lat2,lon2). S
%   is returned as a spherical distance in degrees.  The az output is the
%   azimuth of the arc clockwise from north at the first point (lat1,lon1).
%   All inputs and outputs are in degrees.
%
%   [S,az] = map.geodesy.internal.greatCircleDistance(___, radius) computes
%   the arc length on a sphere with the specified radius.  The latitude and
%   longitude inputs and the azimuth output are in degrees. The arc length
%   output, S, is returned in the same length units as the radius input.
%
%   In general, there are two great circle arcs connecting a pair of points
%   on a sphere; the values returned are for the shorter arc.
%
%   This is an element-wise function, and supports scalar expansion across
%   its first 4 inputs.

% Copyright 2019 The MathWorks, Inc.

    % Strictly speaking, there is no default value for the radius, because
    % none is needed. But we can think of the default radius as rad2deg(1)
    % == 180/pi, because the following give the same results:
    %
    %   S = map.geodesy.internal.greatCircleDistance(lat1,lon1,lat2,lon2)
    %   S = map.geodesy.internal.greatCircleDistance(lat1,lon1,lat2,lon2,rad2deg(1))

    coslat1 = cosd(lat1);
    coslat2 = cosd(lat2);

    % Use the "haversine formula", which ensures that h will be exactly
    % zero whenever isequal(lat2,lat1) && isequal(lon2,lon1).
    h = sind((lat2-lat1)/2).^2 ...
        + coslat1 .* coslat2 .* sind((lon2-lon1)/2).^2;

    S = 2 * asin(sqrt(h));
    if nargin < 5
        S = rad2deg(S);
    else
        S = radius .* S;
    end

    if nargout > 1
        az = atan2d(coslat2 .* sind(lon2-lon1),...
            coslat1 .* sind(lat2) - sind(lat1) .* coslat2 .* cosd(lon2-lon1));
    end
end
