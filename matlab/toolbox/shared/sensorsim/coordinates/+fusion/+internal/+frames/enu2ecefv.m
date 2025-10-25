function ecefv = enu2ecefv(enuv, lat, lon)
%ENU2ECEFV Transform vector from ENU to ECEF
%
%   Inputs
%       enuv - Nx3 vector in ENU
%       lat  - Nx1 latitude vector (deg)
%       lon  - Nx1 longitude vector (deg)
%   Outputs
%       ecefv - Nx3 vector in ECEF
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    rotENUToECEF = fusion.internal.frames.enu2ecefrotmat(lat, lon);

    % Rotate each vector by each corresponding rotation matrix. This
    % is the equivalent of a vectorized matrix multiply:
    %   for v = 1:size(ecefv, 1)
    %       ecefv(v,:) = ( rotENUToECEF(:,:,v) * enuv(v,:).' ).';
    %   end
    permENUV = repmat( permute(enuv, [3 2 1]), 3, 1 );
    ecefv = permute(sum(rotENUToECEF.* permENUV, 2), [3 1 2]);
end
