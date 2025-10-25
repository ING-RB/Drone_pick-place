function c = normAm(A,m,n,isrealA,prec)
%NORMAM   Estimate 1-norm of power of matrix.
%   NORMAM(A,m,n,isrealA,prec) estimates norm(A^m,1) where A is n-by-n
%   and isrealA is 1 if A is real and otherwise 0. Prec is class(A).
%   A can be an explicit matrix or a function AFUN such that
%   FEVAL(@AFUN,FLAG,X) returns the following values for the indicated FLAG:
%     FLAG       return
%     'real'     1 if A is real, 0 otherwise
%     'notransp' A*X
%     'transp'   A'*X
%   where X is a matrix.
%   If A has nonnegative elements the estimate is exact.

%   Reference: 
%   A. H. Al-Mohy and N. J. Higham, A New Scaling and Squaring Algorithm 
%      for the Matrix Exponential, SIAM J. Matrix Anal. Appl. 31(3):
%      970-989, 2009.
%
%   Awad H. Al-Mohy and Nicholas J. Higham
%   Copyright 2014-2023 The MathWorks, Inc.

if isfloat(A) && nargin < 3
   n = size(A,1);
   isrealA = isreal(A);
   prec = class(A);
end
if isfloat(A) && n < 50 % Compute matrix power explicitly
    c = norm(A^m,1);
elseif isfloat(A) && isrealA && all(A >= 0, 'all')
    % For positive matrices only.
    e = ones(n,1,prec);
    for j=1:m
        e = A'*e;
    end
    c = norm(e,inf);
else
    X0 = ones(n,2,prec);
    X0(1:2:end,2) = -1;
    X0 = X0./n;
    fun = @(flag,X) afun_power(flag, X, n, m, A, isrealA);
    c = normest1(fun,2,X0);
end
% End of normAm

function Z = afun_power(flag, X, n, m, A, isrealA)
%AFUN_POWER  Function to evaluate matrix products needed by NORMEST1.
if flag == "dim"
    Z = n;
elseif flag == "real"
    Z = isrealA;
else
    if flag == "notransp"
        if isfloat(A)
            for i = 1:m
                X = A*X;
            end
        else
            for i = 1:m
                X = A("notransp",X);
            end
        end
    elseif flag == "transp"
        if isfloat(A)
            for i = 1:m
                X = A'*X;
            end
        else
            for i = 1:m
                X = A("transp",X);
            end
        end
    end
    Z = X;
end
