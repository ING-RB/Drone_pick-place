function [lat, lon, S] = sampleGreatCircleTrace(lat0, lon0, S0, az0, dS, varargin)
%sampleGreatCircleTrace Evenly sampled great-circle arc traced from start point
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [lat,lon] = map.geodesy.internal.sampleGreatCircleTrace(lat0,lon0,S0,az0,dS)
%   returns equally-spaced points along a great circle arc on a sphere,
%   from a start point with latitude-longitude specified by (lat0, lon0),
%   following an arc with length S0 and initial azimuth angle az0. The
%   azimuth angle input specifies the direction clockwise from north at the
%   start point. The great-circle distance between adjacent points is equal
%   to dS if dS divides evenly into S0, and is somewhat less than dS
%   otherwise. All inputs and outputs are in degrees. All inputs are
%   scalar; the outputs are column vectors.
%
%   [lat,lon] = map.geodesy.internal.sampleGreatCircleTrace(___,radius) performs
%   the computation on a sphere with the specified radius. The latitude and
%   longitude inputs and outputs, and the azimuth angle input, are in
%   degrees. The arc length, S0, and arc length increment, dS, must be
%   specified in the same units as the radius input.
%
%   [___,S] = map.geodesy.internal.sampleGreatCircleTrace(___) returns the
%   cumulative arc length as a column vector the same size as lat and lon,
%   such that S(k) is the distance along the arc from (lat0,lon0) to
%   (lat(k),lon(k)).
%
%   The wrapping of the output longitudes depends on the starting
%   longitude, lon0. It is not guaranteed to fall within any specific
%   range, but can be standardized using either wrapTo180 or wrapTo360.

% Copyright 2019 The MathWorks, Inc.

    narginchk(5,6)
    radius = varargin;
    n = max(1, ceil(S0/dS));
    S = S0 * transpose(((0 : n) / n));
    [lat, lon] = map.geodesy.internal.greatCircleTrace(lat0, lon0, S, az0, radius{:});
    lat(1) = lat0;
    lon(1) = lon0;
end
