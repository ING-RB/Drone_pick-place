function R = enu2ecefrotmat(lat, lon)
%ENU2ECEFROTMAT Rotation matrix to transform ENU to ECEF
%
%   Inputs
%       lat - Nx1 latitude vector (deg)
%       lon - Nx1 longitude vector (deg)
%   Outputs
%       R - 3x3xN ENU to ECEF rotation matrix array
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    permLat = permute(lat, [3 2 1]);
    permLon = permute(lon, [3 2 1]);
    cosLat = cosd(permLat);
    sinLat = sind(permLat);
    cosLon = cosd(permLon);
    sinLon = sind(permLon);

    zero = zeros(1,1,numel(lat), 'like', lat);

    % Calculate ENU to ECEF rotation matrix.
    R = [-sinLon, -sinLat .* cosLon, cosLat .* cosLon;
         cosLon, -sinLat .* sinLon, cosLat .* sinLon;
         zero,            cosLat,           sinLat];
end
