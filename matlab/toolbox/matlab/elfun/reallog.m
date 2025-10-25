function y = reallog(x)
%REALLOG Real logarithm.
%   REALLOG(X) is the natural logarithm of the elements of X.
%   An error is produced if X is negative.
%
%   See also LOG, LOG2, LOG10, EXP, LOGM, REALPOW, REALSQRT.

% Copyright 1984-2022 The MathWorks, Inc.

arguments
    x {mustBeReal}
end

y = log(x);
if ~isreal(y)
    error(message('MATLAB:reallog:complexResult'));
end
