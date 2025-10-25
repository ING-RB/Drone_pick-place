function q = toQuaternion(obj, numQuats, idx)
%This method is for internal use only. It may be removed in the future.

%toQuaternion Convert se3 rotation to quaternion
%   Q = toQuaternion(T) returns a quaternion array, Q,
%   corresponding to the se3 rotation of transformation T. The
%   translational part of T will be ignored. Q will be a column vector of size
%   N-by-1 where N = numel(T). The output quaternions are not
%   normalized .
%
%   Q = toQuaternion(T, NUMQUATS) returns a quaternion vector with size
%   NUMQUATS-by-1. Rotations are repeated until the desired size is
%   reached. This can be helpful in scalar expansion.
%
%   Q = toQuaternion(T, NUMQUATS, IDX) returns a quaternion vector with size
%   N-by-1, where N = max(NUMEL(T),length(IDX)). IDX is a vector of indices
%   into the rotation matrix array.
%   The NUMQUATS input is ignored.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    R = rotm(obj);

    if nargin == 3
        % Only convert the rotation matrices at indices and return
        q = quaternion(R(:,:,idx), "rotmat", "point");
    else
        % Convert all rotation matrices to quaternion column vector
        q = quaternion(R, "rotmat", "point");

        if nargin == 2 && numQuats ~= numel(obj)
            % Repeat rotation as often as requested
            Rrep = repmat(R,1,1,numQuats);
            q = quaternion(Rrep, "rotmat", "point");
        end
    end

end
