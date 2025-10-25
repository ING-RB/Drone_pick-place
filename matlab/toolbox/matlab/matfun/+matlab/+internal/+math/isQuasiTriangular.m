%ISQUASITRIANGULAR Determine whether A has quasi-triangular non-zero structure
%   ISQUASITRIANGULAR(T, 'real') returns true if matrix T is upper
%   quasi-triangular for real matrix T, or upper triangular for complex
%   matrix T.
%
%   ISQUASITRIANGULAR(T, 'complex') returns true if T is upper triangular.
%
%   ISQUASITRIANGULAR(A, B, 'real') returns true if matrices A and B are
%   matching upper quasi-triangular for real matrices A and B, or upper
%   triangular for complex matrices.
%
%   ISQUASITRIANGULAR(A, B, 'complex') returns true if A and B are upper
%   triangular.
%
%   While ISSCHUR checks for consistency of the values in each 2-by-2
%   diagonal block with a Schur decomposition, ISQUASITRIANGULAR only
%   checks the non-zero structure of the matrices.

%   Copyright 2018 The MathWorks, Inc.
