function z = realpow(x, y)
%REALPOW Real power.
%   Z = REALPOW(X,Y) denotes element-by-element powers.  X and Y
%   must have the same dimensions unless one is a scalar. 
%   A scalar can operate into anything.
%
%   An error is produced if the result is complex.
% 
%   See also POWER, MPOWER, REALLOG, REALSQRT.

% Copyright 1984-2022 The MathWorks, Inc.

arguments
    x {mustBeReal}
    y {mustBeReal}
end

z = x .^ y;
if ~isreal(z)
    error(message('MATLAB:realpow:complexResult'));
end