function [lat, lon] = greatCircleTrace(lat0, lon0, S, az, radius)
%greatCircleTrace Trace great circle on sphere
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [lat, lon] = map.geodesy.internal.greatCircleTrace(lat0, lon0, S, az)
%   traces a great circle on a sphere from a start point with latitude-
%   longitude specified by (lat0, lon0) to an end point (lat,lon),
%   following an arc with length S and initial azimuth angle az. The
%   azimuth angle input specifies the direction clockwise from north at the
%   start point.  All inputs and outputs are in degrees; the arc length S
%   is a spherical distance.
%
%   [lat, lon] = map.geodesy.internal.greatCircleTrace(___, radius) traces
%   the great circle on a sphere with the specificed radius. The latitude
%   and longitude inputs and outputs, and the azimuth angle input, are in
%   degrees. The arc length input, S, must be specified in the same units
%   as the radius input.
%
%   The wrapping of the output longitude depends on the starting
%   longitude, lon0. It is not guaranteed to fall within any specific
%   range, but can be standardized using either wrapTo180 or wrapTo360.
%
%   This is an element-wise function, and supports scalar expansion across
%   its first 4 inputs.

% Copyright 2019 The MathWorks, Inc.

    % Reference
    % ---------
    % J. P. Snyder, "Map Projections - A Working Manual,"  US Geological
    % Survey Professional Paper 1395, US Government Printing Office,
    % Washington, DC, 1987, pp. 29-32.

    % Strictly speaking, there is no default value for the radius, because
    % none is needed. But we can think of the default radius as rad2deg(1)
    % == 180/pi, because the following give the same results:
    %
    %   [lat, lon] = map.geodesy.internal.greatCircleTrace(lat0, lon0, S, az)
    %   [lat, lon] = map.geodesy.internal.greatCircleTrace(lat0, lon0, S, az, rad2deg(1))
    
    if nargin < 5
        cosS = cosd(S);
        sinS = sind(S);
    else
        cosS = cos(S ./ radius);
        sinS = sin(S ./ radius);
    end
    
    % Note: At this point, S is the angle in radians subtended by rays from
    % the center of the sphere to the points (lat0,lon0) and (lat,lon) on
    % its surface, so ordinary trig functions are applied to s. The
    % latitude, longitude, and azimuth angles are in degrees, so the
    % functions sind, cosd, and atan2d are used.
    
    lon = lon0 + atan2d( sinS.*sind(az),...
        cosd(lat0).*cosS - sind(lat0).*sinS.*cosd(az) );
    lat = real(asind( sind(lat0).*cosS + cosd(lat0).*sinS.*cosd(az) ));
    
    % The following step ensures that scalar expansion works in the case
    % where all inputs except lon0 are scalar. It also ensures single
    % output in the case where lon0 is the only input of class single.
    lat = lat + zeros(size(lon0),'like',lon0);
end
