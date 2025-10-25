function mustBeNegative(A)
%MUSTBENEGATIVE Validate that value is negative
%   MUSTBENEGATIVE(A) throws an error if A contains nonnegative values.
%   A value is negative if it is less than zero.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       lt, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A < 0, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNegative'));
end
