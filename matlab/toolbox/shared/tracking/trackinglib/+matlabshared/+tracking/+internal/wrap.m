function xw = wrap( x,a,b )
% This function is for internal use only. It may be removed in the future.

% Xw = wrap(X,A,B) wraps the value X into the interval [A, B). Xw is a
% sawtooth wave that has a slope of +1 everywhere, equals X when A<=X<B,
% and has a minimum and supremum value of A and B respectively. If A==B
% then Xw==A==B everywhere. A should be <= B and all inputs should be of
% the same type. No validation is performed.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

if a == b
    % If the endpoints are equal, return that value everywhere except where
    % the input is NaN
    xw = a*ones(size(x),'like',x);
    xw(isnan(x)) = nan;
elseif a == -inf
    % If the lower endpoint is -inf, return the input unchanged where it is
    % less than the upper endpoint, -inf where it is >= to the upper
    % endpoint, and NaN where it is +inf
    xw = x;
    xw(x >= b) = -inf;
    xw(x == inf) = nan;
elseif b == inf
    % If the upper endpoint is inf, return the input unchanged where it is
    % greater than or equal to the lower endpoint, inf where it is less
    % than the lower endpoint, and NaN where it is -inf
    xw = x;
    xw(x < a) = inf;
    xw(x == -inf) = nan;
else
    % Finite endpoints
    xw = mod(x-a,b-a)+a;
end

end