function mustBeGreaterThanOrEqual(A, B)
%MUSTBEGREATERTHANOREQUAL Validate that value is greater than or equal to a specified value
%   MUSTBEGREATERTHANOREQUAL(A,B) throws an error if A is not greater than or equal to B.
%   MATLAB calls ge to determine if A is greater than or equal to B.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       ge, isscalar, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isscalar(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonScalarSecondInput', ...
        'mustBeGreaterThanOrEqual'));
end

if ~isnumeric(B) && ~islogical(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonNumericOrLogicalInput', ...
        'mustBeGreaterThanOrEqual'));
end

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonRealInput', ...
        'mustBeGreaterThanOrEqual'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A >= B, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorExceptionWithValue(...
        matlab.internal.validation.util.createPrintableScalar(B),...
        'MATLAB:validators:mustBeGreaterThanOrEqualGenericText',...
        'MATLAB:validators:mustBeGreaterThanOrEqual'));
end

