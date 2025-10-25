%SYLVESTER_TRI Generalized Sylvester solver for quasi-triangular matrices
%   X = SYLVESTER_TRI(A, B, C, E, F, trans) computes X which solves
%       A*X*F  + E*X*B  = C, if trans is 'notrans'
%       A*X*F' + E*X*B' = C, if trans is 'trans'
%
%   X = SYLVESTER_TRI(A, B, C, 'I', 'I', trans) treats E and F as identity
%   matrices, and computes X which solves
%       A*X + X*B  = C, if trans is 'notrans'
%       A*X + X*B' = C, if trans is 'trans'
%
%   X = SYLVESTER_TRI(A, 'I', C, 'I', F, trans) treats B and E as
%   identity matrices, and computes X which solves
%       A*X*F  + X = C, if trans is 'notrans'
%       A*X*F' + X = C, if trans is 'trans'
%
%   Matrix pairs (A, E) and (B, F) must have nonzero structures consistent
%   with outputs of the QZ function:
%       - Complex case: Matrices must be upper triangular.
%       - Real case: Matrices must be upper quasi-triangular, with matching
%                    2-by-2 blocks on the diagonal allowed.
%   If any of A, B, C, E, F are complex, the matrices A, B, E, F must all
%   be upper triangular.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%  Copyright 2018 The MathWorks, Inc.