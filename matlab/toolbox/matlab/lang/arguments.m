%ARGUMENTS Declare function argument validation 
%   To restrict the values of input arguments, add an arguments validation
%   block after the function line. For example, in the following function,
%   input argument x must be a numeric array:
%
%          %STAT Show interesting statistics.
%          function [mean,stdev] = stat(x)
%          arguments
%              x {mustBeNumeric}
%          end
%          n = length(x);
%          mean = sum(x)/n;
%          stdev = sqrt(sum((x-mean).^2)/n);
%
%   When the stat function is called, MATLAB checks its input value against
%   the restriction and issues an error if x is not a numeric array.
%
%   See also FUNCTION.

%   Copyright 2019 The MathWorks, Inc. 
%   Built-in function.
