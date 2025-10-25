function mustBeInteger(A)
%MUSTBEINTEGER Validate that value is integer
%   MUSTBEINTEGER(A) throws an error if A contains non integer values.
%   A value is integer if it is real, finite, and equal to the result
%   of taking the floor of the value.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       isreal, isfinite, floor, isnumeric, islogical, eq
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

% Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~allfinite(A) || ~all(A == floor(A), 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeInteger'));
end
