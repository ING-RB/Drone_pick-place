function mustBeFloat(A)
%MUSTBEFLOAT Validate that value is a floating-point array
%   MUSTBEFLOAT(A) throws an error if A is not a floating-point array. The
%   floating-point types are single and double, and subclasses of single
%   and double.
% 
%   MATLAB calls isfloat to determine if A is a floating-point array.
%
%   Class support: All MATLAB classes
%
%   See also: ISFLOAT.

%   Copyright 2020-2021 The MathWorks, Inc.

if ~isfloat(A)
    throwAsCaller(MException(message('MATLAB:validators:mustBeFloat')));
end

% LocalWords:  validators
