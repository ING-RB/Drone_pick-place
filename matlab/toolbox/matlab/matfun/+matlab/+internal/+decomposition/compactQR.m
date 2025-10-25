%COMPACTQR Compact QR factorization
%   [H, TAU] = COMPACTQR(A) computes the QR factorization of A and returns
%   R as the upper triangle of H, and Q represented by Householder
%   reflectors stored in the lower triangle of H and in vector TAU.
%   A must be dense and of floating-point type.
%
%   [H, TAU, PERM] = COMPACTQR(A) applies the column-permuted version of QR
%   and returns a permutation vector.
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
