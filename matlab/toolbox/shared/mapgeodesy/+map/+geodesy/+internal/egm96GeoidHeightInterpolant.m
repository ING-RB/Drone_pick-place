function G = egm96GeoidHeightInterpolant()
%egm96GeoidHeightInterpolant Return griddedInterpolant object for EGM96
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.
%
%   G = map.geodesy.internal.egm96GeoidHeightInterpolant() returns a
%   griddedInterpolant object G such that N = G(lat,lon) is an interpolated
%   value for the EGM96 geoid height at the latitudes and longitudes
%   indicated by lat and lon.  N is also known as "undulation" or
%   "departure".  To avoid extrapolation, ensure that -90 <= lat <= 90 for
%   all non-NaN elements of lat, and that 0 <= lon <= 360 for all non-NaN
%   elements of lon.  The lat and lon inputs to G can have any shape, but
%   must be the same size, and must be specified in degrees. They will
%   typically class double, but single is accepted also.  The output N is
%   class single and matches lat and lon in size. For some use cases (e.g.,
%   3D coordinate system transformation), it may be necessary to convert N
%   to double to avoid loss of precision.
%
%   Example
%   -------
%   % Interpolate the geoid height at the summit of Mauna Kea
%   G = map.geodesy.internal.egm96GeoidHeightInterpolant();
%   latmk =   19.8206;
%   lonmk = -155.4681;
%   N = G(min(max(latmk,-90),90),mod(lonmk,360))

% Copyright 2019 The MathWorks, Inc.

    % geoidegm96grid.mat is on the path, in toolbox/shared/mapgeodesy
    s = load('geoidegm96grid.mat');
    
    latg = s.latbp;
    long = s.lonbp;
    
    G = griddedInterpolant({latg,long}, s.grid, 'spline');
end
