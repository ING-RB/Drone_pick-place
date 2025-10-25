function xf = fold( x,a,b )
% This function is for internal use only. It may be removed in the future.

% Xf = fold(X,A,B) folds the value X into the interval [A, B]. Xf is a
% triangle wave that has a slope of +/-1 everywhere, equals X when A<=X<=B,
% and has a minimum and maximum value of A and B respectively. If A==B then
% Xf==A==B everywhere. A should be <= B. No validation is performed.

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen

if a == b
    % If the endpoints are equal, return that value everywhere except where
    % the input is NaN
    xf = a*ones(size(x),'like',x);
    xf(isnan(x)) = nan;
elseif a == -inf
    if b == inf
        % If both endpoints are inf, return x unchanged
        xf = x;
    else
        % The lower endpoint is -inf and the upper endpoint is finite
        xf = b - abs(x - b);
    end
elseif b == inf
    % The upper endpoint is inf and the lower endpoint is finite
    xf = a + abs(x - a);
else
    % Both endpoints are finite
    W = 2*(b-a);
    xf = (x-a)/W;
    xf = W*abs(xf-round(xf)) + a;
end

end