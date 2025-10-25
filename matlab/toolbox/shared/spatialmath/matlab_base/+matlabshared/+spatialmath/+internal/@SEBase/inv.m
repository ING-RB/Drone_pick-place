function Tinv = inv(obj)
%INV Inverse of se3 transformation
%
%   Tinv = INV(T) returns the inverse of the se3 transformation, T.
%
%   The inverse Tinv is formed explicitly and the inversion
%   does not require any matrix inversion. Tinv*T is the identity
%   transformation (zero motion).
%   This function assumes that the transformation is normalized. If the
%   transformation is not normalized, use NORMALIZE.
%
%   See also normalize.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    d = obj.Dim;
    R = rotm(obj);

    % For pagemtimes below, I need the translation in paged form
    t = obj.M(1:d-1, d, :);

    % Rotation matrix can be inverted by transpose (assuming it's orthonormal)
    Rt = pagetranspose(R);

    % Assemble inverse
    Tinv = obj.fromRotmTrvec(Rt, -pagemtimes(Rt,t), size(obj.MInd));

end
