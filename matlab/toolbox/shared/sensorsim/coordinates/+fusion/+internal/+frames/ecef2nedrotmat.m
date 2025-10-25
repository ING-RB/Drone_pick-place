function R = ecef2nedrotmat(lat, lon)
%ECEF2NEDROTMAT Rotation matrix to transform ECEF to NED
%
%   Inputs
%       lat - Nx1 latitude vector (deg)
%       lon - Nx1 longitude vector (deg)
%   Outputs
%       R - 3x3xN ECEF to NED rotation matrix array
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

    % Calculate ECEF to NED rotation matrix.
    R = [-sinLat .* cosLon, -sinLat .* sinLon,  cosLat;...
         -sinLon,            cosLon,    zero;...
         -cosLat .* cosLon, -cosLat .* sinLon, -sinLat];

end
