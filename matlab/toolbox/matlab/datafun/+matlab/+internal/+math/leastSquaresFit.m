function [p, rankV, QRfactor, perm] = leastSquaresFit(V,y)
%leastSquaresFit Solve least squares problem p = V\y
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2020 The MathWorks, Inc.

% Solve least squares problem p = V\y to get polynomial coefficients p.
[QRfactor, tau, perm, rankV, ~] = matlab.internal.decomposition.builtin.qrFactor(V, -2);

% use nonzero diagonal entries to determine rank for qrSolve.
rV = sum(abs(getDiag(QRfactor)) ~= 0);

% QR solve with rank = rV.
p = matlab.internal.decomposition.builtin.qrSolve(QRfactor, tau, perm, y, rV);

function d = getDiag(X)
if isvector(X)
    if isempty(X)
        d = X(:);
    else
        d = X(1);
    end
else
   d = diag(X);
   d = d(:); % handle diag([])
end