function isp = isprime(X)
%ISPRIME True for prime numbers.
%   ISPRIME(X) is 1 for the elements of X that are prime, 0 otherwise.
%
%   Class support for input X:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   See also FACTOR, PRIMES.

%   Copyright 1984-2024 The MathWorks, Inc. 

isp = false(size(X));
X = X(:);
floatX = isfloat(X);
if ~(floatX || isinteger(X)) || ~isreal(X) || ...
        any(X < 0) || any(fix(X) ~= X) || ~allfinite(X)
    error(message('MATLAB:isprime:InputNotPosInt'));
end
if isempty(X)
    return
end

% Pre-compute candidates for prime factors
% Only look for factors up to sqrt(x). Since sqrt does not support
% integers, use a tight general uint64 upper bound based on:
%   sqrt(x) < sqrt( double(x) + eps(double(x) )
dmaxX = double(max(X));
if floatX
    % doubles > flintmax are even, no need to check larger candidates
    dmaxX = min(dmaxX,flintmax);
end
p = primes(uint64(sqrt( dmaxX + eps(dmaxX) )));

% Check for prime factors
np = numel(p);
for k = 1:numel(X)
    Xk = full(X(k));
    if Xk > 1
        % Upper bound for the factors
        dXk = double(Xk);
        ub = uint64(sqrt( dXk + eps(dXk) ));

        % Search for factors
        uXk = uint64(Xk);
        tf = true;
        pj = 1;
        while tf && pj <= np && p(pj) <= ub
            tf = rem(uXk,p(pj)) ~= 0;
            pj = pj + 1;
        end
        isp(k) = tf;
    end
end
