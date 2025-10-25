function mustBeNumericOrLogical(A)
%MUSTBENUMERICORLOGICAL Validate that value is numeric or logical
%   MUSTBENUMERICORLOGICAL(A) throws an error if A contains values that are
%   not numeric or logical. MATLAB calls isnumeric to determine if A is
%   numeric and calls islogical to determine if A is logical.
%
%   See also: ISNUMERIC, ISLOGICAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end
