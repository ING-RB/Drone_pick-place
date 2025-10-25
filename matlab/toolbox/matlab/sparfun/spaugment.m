function S = spaugment(A,c)
%SPAUGMENT Form least squares augmented system.
%   S = SPAUGMENT(A,c) creates the sparse, square, symmetric indefinite
%   matrix S = [c*I A; A' 0].  This matrix is related to the least
%   squares problem
%           min norm(b - A*x)
%   by
%           r = b - A*x
%           S * [r/c; x] = [b; 0].
%
%   The optimum value of the residual scaling factor c, involves
%   min(svd(A)) and norm(r), which are usually too expensive to compute.
%   S = SPAUGMENT(A), without a specified value of c, uses
%   max(max(abs(A)))/1000.
%
%   In previous versions of MATLAB, the augmented matrix was used by
%   sparse linear equation solvers, \ and /, for nonsquare problems,
%   but now MATLAB performs a least squares solve using the qr
%   factorization of A instead.
%
%   See also SPPARMS.

%   Copyright 1984-2024 The MathWorks, Inc. 

if nargin < 2
   outClass = class(A);
   c = max(max(abs(A)))/1000;
else
    outClass = superiorfloat(A,c);
    c = cast(c,outClass);
end
[m,n] = size(A);

support = matlab.internal.feature('SingleSparse');

if support
    S = [sparse(1:m,1:m,c(1)) A; A' sparse(n,n,outClass)];
else
    S = [sparse(1:m,1:m,c(1)) A; A' sparse(n,n)];
end
