function [lat, lon, S] = sampleGreatCircleArc(lat1, lon1, lat2, lon2, dS, varargin)
%sampleGreatCircleArc Evenly sampled great-circle arc connecting end points
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   [lat,lon] = map.geodesy.internal.sampleGreatCircleArc(lat1,lon1,lat2,lon2,dS)
%   returns equally-spaced points along a great circle arc on a sphere
%   connecting a start point with latitude-longitude (lat1,lon1) to an end
%   point (lat2,lon2). The great-circle distance between adjacent output
%   points is equal to dS if dS divides evenly into the total arc length,
%   and is somewhat less than dS otherwise. All inputs and outputs are in
%   degrees. All inputs are scalar; the outputs are column vectors.
%
%   [lat,lon] = map.geodesy.internal.sampleGreatCircleArc(___,radius) performs
%   the computation on a sphere with the specified radius. The latitude
%   and longitude inputs and outputs, and the azimuth angle input, are in
%   degrees. The arc length increment, dS, must be specified in the same
%   units as the radius input.
%
%   [___,S] = map.geodesy.internal.sampleGreatCircleArc(___) returns the
%   cumulative arc length as a column vector the same size as lat and lon,
%   such that S(k) is the distance along the arc from (lat1,lon1) to
%   (lat(k),lon(k)).
%
%   In general, there are two great circle arcs connecting a pair of points
%   on a sphere; the values returned are for the shorter arc.
%
%   The wrapping of the output longitudes depends on the starting
%   longitude, lon1. It is not guaranteed to fall within any specific
%   range, but can be standardized using either wrapTo180 or wrapTo360.

% Copyright 2019 The MathWorks, Inc.

    narginchk(5,6)
    radius = varargin;
    [S0, az0] = map.geodesy.internal.greatCircleDistance(lat1, lon1, lat2, lon2, radius{:});
    [lat, lon, S] = map.geodesy.internal.sampleGreatCircleTrace(lat1, lon1, S0, az0, dS, radius{:});
    lat(end) = lat2;
    lon(end) = lon2;
end
