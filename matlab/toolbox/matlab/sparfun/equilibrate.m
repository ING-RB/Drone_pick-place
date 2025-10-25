function [P, R, C] = equilibrate(A, option)
%EQUILIBRATE Matrix equilibration.
%    [P,R,C] = EQUILIBRATE(A) permutes and rescales a structurally 
%    non-singular matrix A in such a way that the modified matrix 
%
%                           B = R*P*A*C
%
%    has only 1 and -1 on all its diagonal entries, and all its off-diagonal
%    entries are not greater than 1 in magnitude. Matrix A must be square and
%    structurally nonsingular.
%    The output P is a permutation matrix, and R and C are diagonal.
%
%    [P,R,C] = equilibrate(A,outputForm) returns P, R, and C in the form
%    specified by outputForm:
%       'matrix' - (default) P, R, C are matrices such that B = R*P*A*C 
%       'vector' - P, R, C are column vectors such that B = R.*A(P,:).*C' 
%
%    P*A (or A(P,:) with 'vector') is the permutation of A that maximizes  
%    the product of its diagonal values. 
%
%   See also MATCHPAIRS, SPRANK.

%   Copyright 2018-2024 The MathWorks, Inc.
%
%   Reference:
%   I.S. Duff and J. Koster. "On Algorithms For Permuting Large Entries
%   to the Diagonal of a Sparse Matrix."
%   SIAM J. Matrix Anal. & Appl., 22(4), 973-996, 2001.  

[m, n] = size(A);
if ~isfloat(A) || ~ismatrix(A) || m ~= n || isobject(A)
    error(message('MATLAB:equilibrate:InvalidInput'));
elseif ~allfinite(A)
    error(message('MATLAB:equilibrate:NonFiniteInput'));
end

matrixShape = true;
if nargin > 1
    if matlab.internal.math.partialMatchString(option, 'vector')
        matrixShape = false;
    elseif matlab.internal.math.partialMatchString(option, 'matrix')
        matrixShape = true;
    else
        error(message('MATLAB:equilibrate:InvalidOption'));
    end
end

if issparse(A)
    logNzA = -log(abs(nonzeros(A)));
    [perm, ~, u, v] = matlab.internal.graph.perfectMatching(A, logNzA);
else
    logA = -log(abs(A));
    [perm, ~, u, v] = matlab.internal.graph.perfectMatching(logA);
end

% Balance u and v to avoid underflow or overflow: Choose scale such as to
%   minimize max(abs([u-scale; v+scale])).
scale = (min(min(u), -max(v)) + max(max(u), -min(v))) / 2;

u = u - scale;
v = v + scale;

% A perfect matching was found, therefore the matrix is
% structurally singular.
if isempty(perm) && n ~= 0
    error(message('MATLAB:equilibrate:StructSingular'));
end

if matrixShape
   if issparse(A)
       P = sparse(1:n, perm, ones("like", A), n, n);
       R = diag(sparse(exp(u(perm))));
       C = diag(sparse(exp(v)));
   else
       prototype = real(zeros("like", A));
       P = zeros(n, n, "like", prototype);
       P((1:n)'+n*perm-n) = 1;
       R = diag(exp(u(perm)));
       C = diag(exp(v));
   end
else
    P = perm;
    R = exp(u(perm));
    C = exp(v);
end
