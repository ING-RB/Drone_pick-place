%This function is for internal use only. It may be removed in the future.

%LLA2ENU Geodetic LLA to local Cartesian ENU
%   enuPos = lla2enu(llaPos, lla0) converts the M-by-3 array of geodetic
%   LLA coordinates, llaPos, to an M-by-3 array of local Cartesian ENU
%   coordinates, enuPos, given a local coordinate system defined by the
%   geodetic coordinates of its origin, lla0.llaPos is in
%   [degrees degrees meters]. enuPos is in meters. lla0 is in
%   [degrees degrees meters]. The ellipsoid planet is WGS84.

%
%   % Example:
%   % Convert geodetic position to local ENU coordinates based on an origin
%   % near Natick, MA.
%
%   lla0 = [42 -71 53];
%   llaPos = [42.2 -71.4 53];
%   enuPos = fusion.internal.frames.lla2enu(llaPos, lla0);

%   Copyright 2017-2020 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function enuPos = lla2enu(llaPos, lla0)

    ecefPos = fusion.internal.frames.lla2ecef(llaPos);
    enuPos = fusion.internal.frames.ecef2enu(ecefPos, lla0);
end
