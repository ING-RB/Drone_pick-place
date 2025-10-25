%APPLYHOUSEHOLDER Apply Householder reflectors
%   X = APPLYHOUSEHOLDER(H, TAU, B, transp, k) applies orthogonal matrix Q
%   (represented by Householder reflectors stored in H and TAU) to B.
%
%   If transp is false, X = Q*B, otherwise X = Q'*B.
%
%   Input k indicates how many reflectors to use - this should be
%   between 0 and the number of columns of A.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   Example:
%      % Create matrix A and vector b
%      A = [1 2; 3 4; 5 6];
%      b = [9; 8; 7];
%
%      % Compute QR factorization of A using standard method
%      [Q, R] = qr(A)
%
%      % Use compactQR to compute QR, which represents Q as Householder
%      reflectors.
%      [H, tau] = matlab.internal.decomposition.compactQR(A)
%
%      % Compute Q*b using either of the functions.
%      x = Q*b
%      x = matlab.internal.decomposition.applyHouseholder(H, tau, b, false, 2)

%  Copyright 2021 The MathWorks, Inc.
