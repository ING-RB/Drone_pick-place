function Rinv = inv(obj)
%INV Invert rotation
%
%   Rinv = INV(R) returns the inverse of the so2 or so3 rotation, R.
%
%   The inverse Rinv is formed explicitly and the inversion
%   does not require any matrix inversion. Rinv*T is the identity
%   rotation (zero motion).
%   This function assumes that the rotation is normalized. If the
%   rotation is not normalized, use NORMALIZE.
%
%   See also normalize.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    R = rotm(obj);

    % Rotation matrix can be inverted by transpose (assuming it's orthonormal)
    Rt = pagetranspose(R);

    % Assemble inverse
    Rinv = obj.fromMatrix(Rt, size(obj.MInd));

end
