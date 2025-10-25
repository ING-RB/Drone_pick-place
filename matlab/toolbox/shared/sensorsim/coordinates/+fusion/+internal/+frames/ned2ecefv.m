function ecefv = ned2ecefv(nedv, lat, lon)
%NED2ECEFV Transform vector from NED to ECEF
%
%   Inputs
%       nedv - Nx3 vector in NED
%       lat  - Nx1 latitude vector (deg)
%       lon  - Nx1 longitude vector (deg)
%   Outputs
%       ecefv - Nx3 vector in ECEF
%
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    rotNEDToECEF = fusion.internal.frames.ned2ecefrotmat(lat, lon);

    % Rotate each vector by each corresponding rotation matrix. This
    % is the equivalent of a vectorized matrix multiply:
    %   for v = 1:size(ecefv, 1)
    %       ecefv(v,:) = ( rotNEDToECEF(:,:,v) * nedv(v,:).' ).';
    %   end
    permNEDV = repmat( permute(nedv, [3 2 1]), 3, 1 );
    ecefv = permute(sum(rotNEDToECEF.* permNEDV, 2), [3 1 2]);
end
