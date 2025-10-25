%COUPLED_SYLVESTER_TRI Coupled Sylvester solver for quasi-triangular matrices
%   [R, L] = COUPLED_SYLVESTER_TRI(A, B, C, D, E, F) computes R and L which
%   solve the coupled equations A*R + L*B == C, D*R + L*E == F.
%
%   Matrix pairs (A, D) and (B, E) must have nonzero structures consistent
%   with outputs of the QZ function:
%       - Complex case: Matrices must be upper triangular.
%       - Real case: Matrices must be upper quasi-triangular, with matching
%                    2-by-2 blocks on the diagonal allowed.
%   If any of A, B, C, D, E, F is complex, the matrices A, B, D, E must all
%   be upper triangular.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%  Copyright 2018 The MathWorks, Inc.
