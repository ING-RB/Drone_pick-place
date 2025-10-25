function mustBeNonsparse(A)
%mustBeNonsparse Validate that value is nonsparse
%   mustBeNonSparse(A) throws an error if A is sparse.
%   MATLAB calls issparse to determine if A is sparse.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define an issparse method.
%
%   See also: issparse, mustBeNumericOrLogical, mustBeSparse.

%   Copyright 2016-2024 The MathWorks, Inc.

if issparse(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNonsparse'));
end
