function q = toQuaternion(obj, numQuats, idx)
%This method is for internal use only. It may be removed in the future.

%toQuaternion Convert so2 rotation to quaternion
%   Q = toQuaternion(T) returns a quaternion array, Q,
%   corresponding to the so2 rotation T. Q will be a column vector of size
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

    if nargin == 3
        % Convert to 3D rotation. Assume z rotation is 0.
        R = repmat(eye(3,underlyingType(obj)),1,1,numel(idx));
        R(1:2,1:2,:) = obj.M(:,:,idx);

        % Simply convert to column vector of quaternions
        q = quaternion(R, "rotmat", "point");
    else
        % Convert to 3D rotation. Assume z rotation is 0.
        R = repmat(eye(3,underlyingType(obj)),1,1,numel(obj));
        R(1:2,1:2,:) = obj.M;
        q = quaternion(R, "rotmat", "point");

        if nargin == 2 && numQuats ~= numel(obj)
            % Repeat rotation as often as requested
            Rrep = repmat(R,1,1,numQuats);
            q = quaternion(Rrep, "rotmat", "point");
        end
    end

end
