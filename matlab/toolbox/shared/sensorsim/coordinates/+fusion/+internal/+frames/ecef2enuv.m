function enuv = ecef2enuv(ecefv, lat, lon)
%ECEF2ENUV Transform vector from ECEF to ENU
%
%   Inputs
%       ecefv - Nx3 vector in ECEF
%       lat   - Nx1 latitude vector (deg)
%       lon   - Nx1 longitude vector (deg)
%   Outputs
%       enuv - Nx3 vector in ENU
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    rotECEFToENU = fusion.internal.frames.ecef2enurotmat(lat, lon);

    % Rotate each vector by each corresponding rotation matrix. This
    % is the equivalent of a vectorized matrix multiply:
    %   for v = 1:size(ecefv, 1)
    %       enuv(v,:) = ( rotECEFToENU(:,:,v) * ecefv(v,:).' ).';
    %   end
    permECEFV = repmat( permute(ecefv, [3 2 1]), 3, 1 );
    enuv = permute(sum(rotECEFToENU.* permECEFV, 2), [3 1 2]);
end
