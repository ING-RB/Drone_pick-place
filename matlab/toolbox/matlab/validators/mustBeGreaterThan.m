function mustBeGreaterThan(A, B)
%MUSTBEGREATERTHAN Validate that value is greater than a specified value
%   MUSTBEGREATERTHAN(A,B) throws an error if A is not greater than B.
%   MATLAB calls gt to determine if A is greater than B.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       gt, isscalar, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isscalar(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonScalarSecondInput', ...
        'mustBeGreaterThan'));
end

if ~isnumeric(B) && ~islogical(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonNumericOrLogicalInput', ...
        'mustBeGreaterThan'));
end

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonRealInput', ...
        'mustBeGreaterThan'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A > B, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorExceptionWithValue(...
        matlab.internal.validation.util.createPrintableScalar(B),...
        'MATLAB:validators:mustBeGreaterThanGenericText',...
        'MATLAB:validators:mustBeGreaterThan'));
end
