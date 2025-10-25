%This function is for internal use only. It may be removed in the future.

%NED2LLA Local Cartesian NED to geodetic LLA
%   llaPos = ned2lla(nedPos, lla0) converts the M-by-3 array of local
%   Cartesian NED coordinates, nedPos, to an M-by-3 array of geodetic LLA
%   coordinates, llaPos, given a local coordinate system defined by
%   the geodetic coordinates of its origin, lla0. nedPos is in meters.
%   llaPos is in [degrees degrees meters]. lla0 is in
%   [degrees degrees meters]. The ellipsoid planet is WGS84.
%
%
%   % Example:
%   % Convert local NED position to LLA coordinates based on an origin
%   % near Natick, MA.
%
%   lla0 = [42 -71 53];
%   nedPos = [0 0 0];
%   llaPos = fusion.internal.frames.ned2lla(nedPos, lla0);

%   Copyright 2017-2020 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function llaPos = ned2lla(nedPos, lla0)

    enuPos = zeros(size(nedPos), 'like', nedPos);
    enuPos(:,1) = nedPos(:,2);
    enuPos(:,2) = nedPos(:,1);
    enuPos(:,3) = -nedPos(:,3);

    llaPos = fusion.internal.frames.enu2lla(enuPos,lla0);
end
