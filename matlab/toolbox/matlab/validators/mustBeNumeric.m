function mustBeNumeric(A)
%MUSTBENUMERIC Validate that value is numeric
%   MUSTBENUMERIC(A) throws an error if A contains nonnumeric values.
%   MATLAB call isnumeric to determine if a value is numeric.
%
%   See also: ISNUMERIC.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumeric'));
end
