function nedv = ecef2nedv(ecefv, lat, lon)
%ECEF2NEDV Transform vector from ECEF to NED
%
%   Inputs
%       ecefv - Nx3 vector in ECEF
%       lat   - Nx1 latitude vector (deg)
%       lon   - Nx1 longitude vector (deg)
%   Outputs
%       nedv - Nx3 vector in NED
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    rotECEFToNED = fusion.internal.frames.ecef2nedrotmat(lat, lon);

    % Rotate each vector by each corresponding rotation matrix. This
    % is the equivalent of a vectorized matrix multiply:
    %   for v = 1:size(ecefv, 1)
    %       nedv(v,:) = ( rotECEFToNED(:,:,v) * ecefv(v,:).' ).';
    %   end
    permECEFV = repmat( permute(ecefv, [3 2 1]), 3, 1 );
    nedv = permute(sum(rotECEFToNED.* permECEFV, 2), [3 1 2]);
end
