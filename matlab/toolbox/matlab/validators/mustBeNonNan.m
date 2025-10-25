function mustBeNonNan(A)
%MUSTBENONNAN Validate that value is nonNaN
%   MUSTBENONNAN(A) throws an error if A contains values that are NaN.
%   MATLAB calls anynan to determine if a value is NaN.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define an isnan method.
%
%   See also: ISNAN, ANYNAN.

%   Copyright 2016-2024 The MathWorks, Inc.

if anynan(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNonNan'));
end
