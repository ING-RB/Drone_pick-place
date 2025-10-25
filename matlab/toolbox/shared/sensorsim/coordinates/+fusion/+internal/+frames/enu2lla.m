%This function is for internal use only. It may be removed in the future.

%ENU2LLA Local Cartesian ENU to geodetic LLA
%   llaPos = enu2lla(enuPos, lla0) converts the M-by-3 array of local
%   Cartesian ENU coordinates, enuPos, to an M-by-3 array of geodetic LLA
%   coordinates, llaPos, given a local coordinate system defined by
%   the geodetic coordinates of its origin, lla0. enuPos is in meters.
%   llaPos is in [degrees degrees meters]. lla0 is in
%   [degrees degrees meters]. The ellipsoid planet is WGS84.
%
%
%   % Example:
%   % Convert local ENU position to LLA coordinates based on an origin
%   % near Natick, MA.
%
%   lla0 = [42 -71 53];
%   enuPos = [0 0 0];
%   llaPos = fusion.internal.frames.enu2lla(enuPos, lla0);

%   Copyright 2017-2020 The MathWorks, Inc.

% internal function, no error checking is performed

%#codegen

function llaPos = enu2lla(enuPos, lla0)

    ecefPos = fusion.internal.frames.enu2ecef(enuPos,lla0);
    llaPos  = fusion.internal.frames.ecef2lla(ecefPos);
end
