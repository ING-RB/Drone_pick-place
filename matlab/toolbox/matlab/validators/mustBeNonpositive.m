function mustBeNonpositive(A)
%MUSTBENONPOSITIVE Validate that value is not positive
%   MUSTBENONPOSITIVE(A) throws an error if A contains positive values.
%   A value is positive if it is greater than zero.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       le, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A <= 0, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNonpositive'));
end
