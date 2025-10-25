function mustBeFinite(A)
%MUSTBEFINITE Validate that value is finite
%   MUSTBEFINITE(A) throws an error if A contains nonfinite values.
%   MATLAB calls allfinite to determine if A is finite.
%
%   Class support:
%   All numeric classes, logical, char
%   MATLAB classes that define a isfinite method.
%
%   See also ISFINITE, ALLFINITE.

%   Copyright 2019-2024 The MathWorks, Inc.

try
    if ~allfinite(A)
        throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeFinite'));
    end
catch me 
    % When allfinite errors, A is considered as nonfinite value.
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeFinite'));
end
