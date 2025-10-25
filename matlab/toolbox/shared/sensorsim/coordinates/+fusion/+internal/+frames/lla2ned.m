%This function is for internal use only. It may be removed in the future.

%LLA2NED Geodetic LLA to local Cartesian NED
%   nedPos = lla2ned(llaPos, lla0) converts the M-by-3 array of geodetic
%   LLA coordinates, llaPos, to an M-by-3 array of local Cartesian NED
%   coordinates, nedPos, given a local coordinate system defined by the
%   geodetic coordinates of its origin, lla0.llaPos is in
%   [degrees degrees meters]. nedPos is in meters. lla0 is in
%   [degrees degrees meters]. The ellipsoid planet is WGS84.

%
%   % Example:
%   % Convert geodetic position to local NED coordinates based on an origin
%   % near Natick, MA.
%
%   lla0 = [42 -71 53];
%   llaPos = [42.2 -71.4 53];
%   nedPos = fusion.internal.frames.lla2ned(llaPos, lla0);

%   Copyright 2017-2020 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function nedPos = lla2ned(llaPos, lla0)

    enuPos = fusion.internal.frames.lla2enu(llaPos,lla0);

    nedPos = zeros(size(enuPos), 'like', enuPos);
    nedPos(:,1) = enuPos(:,2);
    nedPos(:,2) = enuPos(:,1);
    nedPos(:,3) = -enuPos(:,3);
end
