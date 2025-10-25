function [lla, gnssVel, hdop, vdop, info] = receiverposition(p, satPos, pdot, satVel)
%RECEIVERPOSITION Estimate GNSS receiver position and velocity
%   lla = RECEIVERPOSITION(p, satPos) returns the receiver position, lla,
%   estimated from the pseudoranges, p, in meters, and the satellite
%   positions, satPos, in meters in the Earth-Centered-Earth-Fixed (ECEF)
%   coordinate system. The output position, lla, is specified in geodetic
%   coordinates in (latitude-longitude-altitude) in (degrees, degrees,
%   meters) respectively.
%
%   [lla, gnssVel] = RECEIVERPOSITION(..., pdot, satVel) returns the
%   receiver velocity, gnssVel, estimated from the pseudorange rates, in
%   meters per second, and the satellite velocities, satVel, in meters per
%   second in the ECEF coordinate system. The output velocity, gnssVel, is
%   specified in the North-East-Down (NED) coordinate system.
%
%   [lla, gnssVel, hdop, vdop] = RECEIVERPOSITION(...) returns horizontal
%   dilution of precision, hdop, and the vertical dilution of precision,
%   vdop, associated with the position estimate.
%
%   [lla, gnssVel, hdop, vdop, info] = RECEIVERPOSITION(...) returns the
%   information struct, info, with the following fields:
%       ClockBias  - Estimated bias error in receiver clock (s)
%       ClockDrift - Estimated drift error in receiver clock (s/s)
%       TDOP       - Time dilution of precision
%
%   Example:
%       recPos = [42 -71 50];
%       recVel = [1 2 3];
%       t = datetime('now');
%       % Obtain satellite positions and velocities at the current time.
%       [gpsSatPos, gpsSatVel] = gnssconstellation(t);
%       [az, el, vis] = lookangles(recPos, gpsSatPos);
%       [p, pdot] = pseudoranges(recPos, gpsSatPos, recVel, gpsSatVel);
%       [lla, gnssVel] = receiverposition(p(vis), gpsSatPos(vis,:), ...
%           pdot(vis), gpsSatVel(vis,:));
%
%   See also gnssconstellation, pseudoranges, lookangles, gnssSensor.

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

narginchk(2, 4);

validateattributes(p, {'double', 'single'}, {'vector', 'real', 'finite'});
N = numel(p);
validateattributes(satPos, {'double', 'single'}, ...
    {'2d', 'nrows', N, 'ncols', 3, 'real', 'finite'});

if (nargin == 2)
    pdot = zeros(size(p), 'like', p);
    satVel = zeros(size(satPos), 'like', satPos);
else
    coder.internal.errorIf(nargin == 3, 'MATLAB:minrhs');
end
validateattributes(pdot, {'double', 'single'}, ...
    {'vector', 'numel', N, 'real', 'finite'});
validateattributes(satVel, {'double', 'single'}, ...
    {'2d', 'nrows', N, 'ncols', 3, 'real', 'finite'});

refFrame = fusion.internal.frames.NED;

initPosECEF = [0 0 0];
initVelECEF = [0 0 0];
[posECEF, gnssVelECEF, dopMatrix, clkBias, clkDrift] ...
    = nav.internal.gnss.computeLocation( ...
    p, pdot, satPos, satVel, initPosECEF, initVelECEF);

lla = fusion.internal.frames.ecef2lla(posECEF);
gnssVel = refFrame.ecef2framev(gnssVelECEF, ...
    lla(1), lla(2));

% Convert DOP matrix from ECEF to local NAV frame and extract horizontal
% and vertical dilutions of precision.
[hdop, vdop, ~, ~, tdop] = nav.internal.gnss.calculateDOP( ...
    dopMatrix, refFrame, lla);

info = struct("ClockBias", clkBias, "ClockDrift", clkDrift, "TDOP", tdop);
end
