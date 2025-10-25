function Rn = normalizeRotm(obj, method)
%This method is for internal use only. It may be removed in the future.

%normalizeRotm Normalize 2D or 3D rotation matrix
%   RN = normalizeRotm(OBJ, METHOD) extracts and normalizes the rotation
%   matrix from SE/SO object OBJ with
%   the normalization algorithm, METHOD, and returns the normalized matrix
%   in RN.
%   METHOD can be in ["quaternion","svd","cross"]

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    switch method
      case "quaternion"
        % Convert to quaternion and normalize that
        q = toQuaternion(obj);
        qn = normalize(q);
        Rn = quatToRotm(obj, qn);

      case "svd"
        % Basic idea: Set singular values to 1 (set S to identity)
        % [U,S,V] = svd(R);
        % Rn = U*V';
        R = rotm(obj);
        Rn = zeros(size(R),"like",R);
        for i = 1:size(R,3)
            [U,~,V] = svd(R(:,:,i));
            Rn(:,:,i) = U*V.';
        end
        % The following code would be more compact, but does not work in
        % codegen as of 23a.
        % [U,~,V] = pagesvd(R);
        % Rn = pagemtimes(U, "none", V, "transpose");

      case "cross"
        % If R = [N,O,A], the O and A vectors are made unit length and the
        % normal vector is formed from N = OxA. Then, we ensure that O and
        % A are orthogonal by O = A x N.
        % Only the direction of A (the z-axis) is unchanged.

        % This method only works for a 3D rotation matrix, so makes sure
        % that 2D matrices are converted.
        Rm = rotm(obj);
        R = to3DRotm(Rm);

        o = R(:,2,:);
        a = R(:,3,:);
        n = cross(o, a);         % N = O x A
        o = cross(a, n);         % O = A x N
        Rn = toDim([n./vecnorm(n) o./vecnorm(o) a./vecnorm(a)], Rm);

      otherwise
        Rn = rotm(obj);
    end

end

function R3 = to3DRotm(R)
%to3DRotm Convert input R to 3D rotation matrix R3

    if size(R,1) == 3
        % Do nothing if it's already 3D
        R3 = R;
    else
        % If it's 2D, embed in 3D identity
        R3 = robotics.internal.rotm2tform(R);
    end
end

function Rn = toDim(R,Rm)
%toDim Change size of R to match Rm
%   This ensures that the output rotation matrix is of the same size as the
%   input rotation matrix.

    if size(R,1) == size(Rm,1)
        % If sizes already match, simply return R
        Rn = R;
    else
        % Extract submatrix to match expected size
        Rn = robotics.internal.tform2rotm(R);
    end
end
