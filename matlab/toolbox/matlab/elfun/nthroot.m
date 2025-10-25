function y = nthroot(x, n)
%NTHROOT Real n-th root of real numbers.
%
%   NTHROOT(X, N) returns the real Nth root of the elements of X.
%   Both X and N must be real, and if X is negative, N must be an odd integer.
%
%   Class support for inputs X, N:
%      float: double, single
%
%   See also POWER.

%   Thanks to Peter J. Acklam
%   Copyright 1984-2024 The MathWorks, Inc.

if ~isreal(x) || ~isreal(n)
    error(message('MATLAB:nthroot:ComplexInput'));
end

if any(x < 0 & mod(n,2)~=1, 'all')
    error(message('MATLAB:nthroot:NegXNotOddIntegerN'));
end

y = (sign(x) + (x==0)) .* (abs(x).^(1./n));

% Correct numerical errors (since, e.g., 64^(1/3) is not exactly 4)
% by one iteration of Newton's method
m = x ~= 0 & (abs(x) < 1./eps("like",y)) & isfinite(n);
if any(m, 'all')
    yNewton = y - (y.^n - x) ./ (n .* y.^(n-1));
    if all(m, 'all')
        y = yNewton;
    else
        y(m) = yNewton(m);
    end
end

