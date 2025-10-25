function r = roots(c)
%ROOTS  Find polynomial roots.
%   ROOTS(C) computes the roots of the polynomial whose coefficients
%   are the elements of the vector C. If C has N+1 components,
%   the polynomial is C(1)*X^N + ... + C(N)*X + C(N+1).
%
%   Note:  Leading zeros in C are discarded first.  Then, leading relative
%   zeros are removed as well.  That is, if division by the leading
%   coefficient results in overflow, all coefficients up to the first
%   coefficient where overflow occurred are also discarded.  This process is
%   repeated until the leading coefficient is not a relative zero.
%
%   Class support for input c: 
%      float: double, single
%
%   See also POLY, RESIDUE, FZERO.

%   Copyright 1984-2024 The MathWorks, Inc.

% ROOTS finds the eigenvalues of the associated companion matrix.

if ~isempty(c) && ~isvector(c)
    error(message('MATLAB:roots:NonVectorInput'));
end

if ~allfinite(c)
    error(message('MATLAB:roots:NonFiniteInput'));
end

c = c(:).';
n = size(c,2);

inz = find(c);
if isempty(inz)
    % All elements are zero    
    r = zeros(0,1,class(c));  
    return
end

fullPrototype = full(zeros("like",c));

% Strip leading zeros and throw away.  
% Strip trailing zeros, but remember them as roots at zero.
nnz = length(inz);
c = c(inz(1):inz(nnz));
r = zeros(n-inz(nnz),1,"like",fullPrototype);  

% Prevent relatively small leading coefficients from introducing Inf
% by removing them.
d = c(2:end)./c(1);
while any(isinf(d))
    c = c(2:end);
    d = c(2:end)./c(1);
end

% Polynomial roots via a companion matrix
n = length(c);
if n > 1
    a = zeros(n-1,n-1,"like",fullPrototype);
    a(1,:) = -d;    
    a(2:n:end) = 1;
    r = [r;eig(a)];
end
