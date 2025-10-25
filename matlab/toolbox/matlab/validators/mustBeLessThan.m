function mustBeLessThan(A, B)
%MUSTBELESSTHAN Validate that value is less than a specified value
%   MUSTBELESSTHAN(A,B) throws an error if A is not less than B.
%   MATLAB calls lt to determine if A is less than B.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       lt, isscalar, isreal, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL, MUSTBEREAL.

%   Copyright 2016-2024 The MathWorks, Inc.
%

if ~isscalar(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonScalarSecondInput', ...
        'mustBeLessThan'));
end

if ~isnumeric(B) && ~islogical(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonNumericOrLogicalInput', ...
        'mustBeLessThan'));
end

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(B)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validatorUsage:nonRealInput', ...
        'mustBeLessThan'));
end

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~all(A < B, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorExceptionWithValue(...
        matlab.internal.validation.util.createPrintableScalar(B),...
        'MATLAB:validators:mustBeLessThanGenericText',...
        'MATLAB:validators:mustBeLessThan'));
end
