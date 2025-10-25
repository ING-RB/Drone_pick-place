function [q,r] = polydiv(b,a)
%POLYDIV Polynomial long division.
%   [Q,R] = POLYDIV(B,A) divides the polynomial whose coefficients are
%   given by vector A out of the polynomial whose coefficients are given
%   by vector B. The result is returned in the quotient polynomial whose
%   coefficients are in the vector Q and the remainder polynomial whose
%   coefficients are in the vector R.
%
%   The outputs satisfy B = conv(A,Q) + R when length(A) <= length(B);
%   otherwise, Q = 0 and R = B. With K = min(length(A),length(B)), these
%   two cases can be written as B = conv(A(1:K),Q) + R.
%
%   Class support for inputs B,A:
%      float: double, single
%
%   See also CONV, RESIDUE, DECONV, POLYVAL.

%   Copyright 2023 The MathWorks, Inc.

if a(1) == 0
    error(message('MATLAB:deconv:ZeroCoef1'))
end
[mb,nb] = size(b);
nb = max(mb,nb);
na = length(a);
if na > nb
    q = zeros(superiorfloat(b,a));
    r = cast(b,class(q));
else
    % Polynomial long division is the same operation
    % as a digital filter's impulse response B(z)/A(z):
    if nargout > 1
        [q,zf] = filter(b, a, [1 zeros(1,nb-na)]);
    else
        q = filter(b, a, [1 zeros(1,nb-na)]);
    end
    if mb ~= 1
        q = q(:);
    end
    if nargout > 1
        r = zeros(size(b),class(q));
        lq = length(q);
        r(lq+1:end) = a(1)*zf(1:nb-lq);
    end
end
end