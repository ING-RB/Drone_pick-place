function y = realsqrt(x)
%REALSQRT Real square root.
%   REALSQRT(X) is the square root of the elements of X.  An
%   error is produced if X is negative.
%
%   See also SQRT, SQRTM, REALLOG, REALPOW.

% Copyright 1984-2022 The MathWorks, Inc.

arguments
    x {mustBeReal}
end

y = sqrt(x);
if ~isreal(y)
    error(message('MATLAB:realsqrt:complexResult'));
end