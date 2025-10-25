function mustBeLessThanOrEqual(A, B)
%MUSTBELESSTHANOREQUAL Validate that value is less than or equal to a specified value
%   MUSTBELESSTHANOREQUAL(A,B) throws an error if A is not less than or equal to B.
%   MATLAB calls le to determine if A is less than or equal to B.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       le, isscalar, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isscalar(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonScalarSecondInput', ...
        'mustBeLessThanOrEqual'));
end

if ~isnumeric(B) && ~islogical(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonNumericOrLogicalInput', ...
        'mustBeLessThanOrEqual'));
end

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonRealInput', ...
        'mustBeLessThanOrEqual'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A <= B, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorExceptionWithValue(...
        matlab.internal.validation.util.createPrintableScalar(B),...
        'MATLAB:validators:mustBeLessThanOrEqualGenericText',...
        'MATLAB:validators:mustBeLessThanOrEqual'));
end
