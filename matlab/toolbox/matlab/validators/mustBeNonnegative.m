function mustBeNonnegative(A)
%MUSTBENONNEGATIVE Validate that value is nonnegative
%   MUSTBENONNEGATIVE(A) throws an error if A contains negative values.
%   A value is nonnegative if it is greater than or equal to zero.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       ge, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A >= 0, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNonnegative'));
end
